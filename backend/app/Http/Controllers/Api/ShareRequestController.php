<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Item;
use App\Models\ShareRequest;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Share requests — every action runs in ONE transaction: the request change,
 * the item / counter change and the notification(s) succeed or fail together.
 *
 * Status flow:
 *   pending ──▶ accepted ──▶ completed      (donor)
 *      │──▶ rejected                        (donor)
 *      └──▶ cancelled (also from accepted)  (requester)
 */
class ShareRequestController extends Controller
{
    /**
     * ?as=requester|donor  → my sent / received requests
     * ?itemId=X            → all requests for one of my items (donor view)
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $query = ShareRequest::query();
        if ($itemId = $request->query('itemId')) {
            $query->where('item_id', $itemId);
            if (! $user->isAdmin()) {
                $query->where('donor_id', $user->id);
            }
        } elseif ($request->query('as') === 'donor') {
            $query->where('donor_id', $user->id);
        } else {
            $query->where('requester_id', $user->id);
        }

        return response()->json($query->orderByDesc('created_at')->get()->map->toApi()->values());
    }

    public function show(Request $request, string $id)
    {
        $r = ShareRequest::find($id) ?? throw ApiError::notFound('Request not found.');
        $this->requireParty($request->user(), $r);

        return response()->json($r->toApi());
    }

    public function store(Request $request)
    {
        $user = $request->user();
        if (! $user->canRequest()) {
            throw ApiError::forbidden($user->is_banned ? 'Your account is suspended.' : 'Your role cannot request items.');
        }
        $data = $request->validate([
            'itemId' => ['required', 'string'],
            'message' => ['required', 'string', 'min:5', 'max:500'],
            'antiResellAgreed' => ['required', 'accepted'],
            'requestId' => ['sometimes', 'string'],
        ], [
            'message.min' => 'Tell the donor why you need it (min 5 characters)',
            'antiResellAgreed.accepted' => 'Please accept: "I confirm that I will not resell this donated item."',
        ]);

        $r = DB::transaction(function () use ($data, $user) {
            $item = Item::lockForUpdate()->find($data['itemId']) ?? throw ApiError::notFound('Item not found.');
            if ($item->donor_id === $user->id) {
                throw ApiError::invalid('You cannot request your own item.');
            }
            if ($item->status !== 'available') {
                throw ApiError::invalid('This item is no longer available.', 'not-available');
            }
            $id = ShareRequest::idFor($item->id, $user->id);
            if (isset($data['requestId']) && $data['requestId'] !== $id) {
                throw ApiError::invalid('Invalid request id.');
            }
            if (ShareRequest::whereKey($id)->exists()) {
                throw ApiError::conflict('You have already requested this item.');
            }

            $r = ShareRequest::create([
                'id' => $id,
                'item_id' => $item->id,
                'item_title' => $item->title,
                'donor_id' => $item->donor_id,
                'requester_id' => $user->id,
                'message' => trim($data['message']),
                'anti_resell_agreed' => true,
                'status' => 'pending',
            ]);
            $item->increment('request_count');
            $user->increment('request_count');
            AppNotification::forRequest($r, $item->donor_id, $user->id, 'new_request',
                'New request for your item', "Someone requested \"{$item->title}\"");

            return $r;
        });

        return response()->json($r->toApi(), 201);
    }

    /** Donor selects this requester → item reserved, every other pending request declined. */
    public function accept(Request $request, string $id)
    {
        $r = DB::transaction(function () use ($request, $id) {
            $r = $this->lockedForDonor($request->user(), $id);
            if ($r->status !== 'pending') {
                throw ApiError::invalid('Only pending requests can be accepted.');
            }
            $r->update(['status' => 'accepted']);
            Item::whereKey($r->item_id)->update(['status' => 'reserved', 'updated_at' => now()]);
            AppNotification::forRequest($r, $r->requester_id, $r->donor_id, 'request_accepted',
                'Request accepted 🎉', "Your request for \"{$r->item_title}\" was accepted. Contact details are now visible.");

            $others = ShareRequest::where('item_id', $r->item_id)
                ->where('id', '!=', $r->id)->where('status', 'pending')->get();
            foreach ($others as $other) {
                $other->update(['status' => 'rejected']);
                AppNotification::forRequest($other, $other->requester_id, $other->donor_id, 'request_rejected',
                    'Request update', "\"{$other->item_title}\" went to another requester this time.");
            }

            return $r;
        });

        return response()->json($r->toApi());
    }

    public function reject(Request $request, string $id)
    {
        $r = DB::transaction(function () use ($request, $id) {
            $r = $this->lockedForDonor($request->user(), $id);
            if ($r->status !== 'pending') {
                throw ApiError::invalid('Only pending requests can be declined.');
            }
            $r->update(['status' => 'rejected']);
            AppNotification::forRequest($r, $r->requester_id, $r->donor_id, 'request_rejected',
                'Request update', "Your request for \"{$r->item_title}\" was not accepted");

            return $r;
        });

        return response()->json($r->toApi());
    }

    /** Handover done → item donated; donor counters updated (all-time + month). */
    public function complete(Request $request, string $id)
    {
        $r = DB::transaction(function () use ($request, $id) {
            $r = $this->lockedForDonor($request->user(), $id);
            if ($r->status !== 'accepted') {
                throw ApiError::invalid('Accept the request first.');
            }
            $r->update(['status' => 'completed']);
            Item::whereKey($r->item_id)->update(['status' => 'donated', 'updated_at' => now()]);
            User::lockForUpdate()->findOrFail($r->donor_id)->recordDonation();
            AppNotification::forRequest($r, $r->requester_id, $r->donor_id, 'request_completed',
                'Donation completed', "Please rate your exchange for \"{$r->item_title}\"");

            return $r;
        });

        return response()->json($r->toApi());
    }

    /** Requester withdraws. If it was already accepted, the item becomes available again. */
    public function cancel(Request $request, string $id)
    {
        $r = DB::transaction(function () use ($request, $id) {
            $r = ShareRequest::lockForUpdate()->find($id) ?? throw ApiError::notFound('Request not found.');
            if ($r->requester_id !== $request->user()->id) {
                throw ApiError::forbidden('Only the requester can cancel.');
            }
            if (! in_array($r->status, ['pending', 'accepted'], true)) {
                throw ApiError::invalid('This request can no longer be cancelled.');
            }
            $wasAccepted = $r->status === 'accepted';
            $r->update(['status' => 'cancelled']);
            if ($wasAccepted) {
                Item::whereKey($r->item_id)->where('status', 'reserved')
                    ->update(['status' => 'available', 'updated_at' => now()]);
            }
            AppNotification::forRequest($r, $r->donor_id, $r->requester_id, 'request_cancelled',
                'Request cancelled', "A request for \"{$r->item_title}\" was cancelled");

            return $r;
        });

        return response()->json($r->toApi());
    }

    /** Either side picks direct handover, courier or on-demand delivery once accepted. */
    public function setHandover(Request $request, string $id)
    {
        $data = $request->validate(['handoverMethod' => ['required', Rule::in(ShareRequest::HANDOVER_METHODS)]]);
        $r = ShareRequest::find($id) ?? throw ApiError::notFound('Request not found.');
        if (! $r->involves($request->user())) {
            throw ApiError::forbidden('Only the donor or requester can choose this.');
        }
        if ($r->status !== 'accepted') {
            throw ApiError::invalid('Choose a handover method after the request is accepted.');
        }
        $r->update(['handover_method' => $data['handoverMethod']]);

        return response()->json($r->toApi());
    }

    private function lockedForDonor(User $user, string $id): ShareRequest
    {
        $r = ShareRequest::lockForUpdate()->find($id) ?? throw ApiError::notFound('Request not found.');
        if ($r->donor_id !== $user->id) {
            throw ApiError::forbidden('Only the donor can do this.');
        }

        return $r;
    }

    private function requireParty(User $user, ShareRequest $r): void
    {
        if (! $r->involves($user) && ! $user->isAdmin()) {
            throw ApiError::forbidden();
        }
    }
}
