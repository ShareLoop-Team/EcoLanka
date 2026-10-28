<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        return response()->json(
            AppNotification::where('user_id', $request->user()->id)
                ->orderByDesc('created_at')->orderByDesc('id')->limit(200)->get()->map->toApi()->values()
        );
    }

    public function markRead(Request $request, string $id)
    {
        $n = AppNotification::find($id) ?? throw ApiError::notFound();
        if ($n->user_id !== $request->user()->id) {
            throw ApiError::forbidden();
        }
        $n->update(['read' => true]);

        return response()->json($n->toApi());
    }

    public function markAllRead(Request $request)
    {
        $data = $request->validate(['ids' => ['present', 'array'], 'ids.*' => ['string']]);
        $count = AppNotification::where('user_id', $request->user()->id)
            ->whereIn('id', $data['ids'])->update(['read' => true]);

        return response()->json(['updated' => $count]);
    }
}
