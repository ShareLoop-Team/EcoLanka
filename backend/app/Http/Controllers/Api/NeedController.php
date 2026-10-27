<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Item;
use App\Models\Need;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** "Item Requests" — people post what they need and why. */
class NeedController extends Controller
{
    public function index(Request $request)
    {
        $query = Need::query();
        if ($requester = $request->query('requesterId')) {
            $query->where('requester_id', $requester);
        } else {
            $query->limit(150);
        }

        return response()->json($query->orderByDesc('created_at')->get()->map->toApi()->values());
    }

    public function show(string $id)
    {
        $need = Need::find($id) ?? throw ApiError::notFound('Request not found.');

        return response()->json($need->toApi());
    }

    public function store(Request $request)
    {
        $user = $request->user();
        if (! $user->canRequest()) {
            throw ApiError::forbidden($user->is_banned ? 'Your account is suspended.' : 'Your role cannot post requests.');
        }
        $data = $request->validate([
            'title' => ['required', 'string', 'min:3', 'max:80'],
            'description' => ['nullable', 'string', 'max:1000'],
            'reason' => ['required', 'string', 'min:5', 'max:500'],
            'categoryId' => ['required', 'string', 'max:32'],
            'district' => ['required', 'string', 'max:40'],
            'city' => ['nullable', 'string', 'max:80'],
            'antiResellAgreed' => ['required', 'accepted'],
        ], ['antiResellAgreed.accepted' => 'Please accept: "I confirm that I will not resell this donated item."']);

        $need = Need::create([
            'requester_id' => $user->id,
            'title' => trim($data['title']),
            'description' => trim($data['description'] ?? ''),
            'reason' => trim($data['reason']),
            'category_id' => $data['categoryId'],
            'district' => $data['district'],
            'city' => trim($data['city'] ?? ''),
            'status' => 'open',
            'anti_resell_agreed' => true,
        ]);

        return response()->json($need->toApi(), 201);
    }

    public function setStatus(Request $request, string $id)
    {
        $need = Need::find($id) ?? throw ApiError::notFound('Request not found.');
        $user = $request->user();
        if ($need->requester_id !== $user->id && ! $user->isAdmin()) {
            throw ApiError::forbidden('Only the person who posted this can change it.');
        }
        $data = $request->validate(['status' => ['required', Rule::in(Need::STATUSES)]]);
        $need->update(['status' => $data['status']]);

        return response()->json($need->toApi());
    }

    /** A donor tells the need's poster that their new item matches it. */
    public function notifyMatch(Request $request, string $id)
    {
        $need = Need::find($id) ?? throw ApiError::notFound('Request not found.');
        $data = $request->validate(['itemId' => ['required', 'string']]);
        $item = Item::find($data['itemId']) ?? throw ApiError::notFound('Item not found.');
        $user = $request->user();
        if ($item->donor_id !== $user->id) {
            throw ApiError::forbidden('You can only match your own items.');
        }
        if ($need->requester_id === $user->id) {
            throw ApiError::invalid('This is your own request.');
        }

        $n = AppNotification::create([
            'user_id' => $need->requester_id,
            'sender_id' => $user->id,
            'type' => 'need_match',
            'title' => 'Someone has what you need 🎁',
            'body' => "\"{$item->title}\" was shared for your request \"{$need->title}\"",
            'need_id' => $need->id,
            'item_id' => $item->id,
            'read' => false,
        ]);

        return response()->json($n->toApi(), 201);
    }
}
