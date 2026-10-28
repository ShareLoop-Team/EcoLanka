<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\ShareRequest;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/** Two-way star ratings after a completed exchange (one per person per request). */
class ReviewController extends Controller
{
    public function index(Request $request)
    {
        $data = $request->validate(['revieweeId' => ['required', 'string']]);

        return response()->json(
            Review::where('reviewee_id', $data['revieweeId'])->orderByDesc('created_at')->get()->map->toApi()->values()
        );
    }

    /** Has the signed-in user already reviewed ?requestId= ? */
    public function mine(Request $request)
    {
        $data = $request->validate(['requestId' => ['required', 'string']]);
        $exists = Review::whereKey($data['requestId'].'_'.$request->user()->id)->exists();

        return response()->json(['exists' => $exists]);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'requestId' => ['required', 'string'],
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:500'],
        ], ['rating.between' => 'Pick 1 to 5 stars.']);

        $review = DB::transaction(function () use ($data, $user) {
            $r = ShareRequest::find($data['requestId']) ?? throw ApiError::notFound('Request not found.');
            if (! $r->involves($user)) {
                throw ApiError::forbidden('Only the two people in this exchange can review it.');
            }
            if ($r->status !== 'completed') {
                throw ApiError::invalid('You can review after the handover.');
            }
            $id = $r->id.'_'.$user->id;
            if (Review::whereKey($id)->exists()) {
                throw ApiError::conflict('You already reviewed this exchange.');
            }
            $revieweeId = $user->id === $r->donor_id ? $r->requester_id : $r->donor_id;
            $review = Review::create([
                'id' => $id,
                'request_id' => $r->id,
                'reviewer_id' => $user->id,
                'reviewee_id' => $revieweeId,
                'rating' => $data['rating'],
                'comment' => trim($data['comment'] ?? ''),
            ]);
            $avg = Review::where('reviewee_id', $revieweeId)->avg('rating');
            User::whereKey($revieweeId)->update(['rating' => round((float) $avg, 2)]);

            return $review;
        });

        return response()->json($review->toApi(), 201);
    }
}
