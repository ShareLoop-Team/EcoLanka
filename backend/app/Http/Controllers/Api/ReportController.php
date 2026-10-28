<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\Report;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Trust & safety: anyone can report a user / item once; admins review. */
class ReportController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'targetType' => ['required', Rule::in(Report::TARGET_TYPES)],
            'targetId' => ['required', 'string', 'max:64'],
            'reason' => ['required', Rule::in(Report::REASONS)],
            'details' => ['nullable', 'string', 'max:500'],
            'evidence' => ['sometimes', 'array', 'max:5'],
            'evidence.*' => ['string', 'max:500'],
        ]);
        $id = "{$data['targetType']}_{$data['targetId']}_{$user->id}";
        if (Report::whereKey($id)->exists()) {
            throw ApiError::conflict('You already reported this.');
        }
        $report = Report::create([
            'id' => $id,
            'reporter_id' => $user->id,
            'target_type' => $data['targetType'],
            'target_id' => $data['targetId'],
            'reason' => $data['reason'],
            'details' => trim($data['details'] ?? ''),
            'evidence' => $data['evidence'] ?? [],
            'status' => 'open',
        ]);

        return response()->json($report->toApi(), 201);
    }

    public function index(Request $request)
    {
        $this->requireAdmin($request);

        return response()->json(Report::orderByDesc('created_at')->get()->map->toApi()->values());
    }

    public function update(Request $request, string $id)
    {
        $this->requireAdmin($request);
        $report = Report::find($id) ?? throw ApiError::notFound('Report not found.');
        $data = $request->validate(['status' => ['required', Rule::in(Report::STATUSES)]]);
        $report->update(['status' => $data['status']]);

        return response()->json($report->toApi());
    }

    private function requireAdmin(Request $request): void
    {
        if (! $request->user()->isAdmin()) {
            throw ApiError::forbidden('Admins only.');
        }
    }
}
