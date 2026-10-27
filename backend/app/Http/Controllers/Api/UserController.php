<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\Api;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /** A profile (404 until the person has finished profile setup). */
    public function show(string $uid)
    {
        $user = User::find($uid);
        if ($user === null || ! $user->hasProfile()) {
            throw ApiError::notFound('Profile not found.');
        }

        return response()->json($user->toApi());
    }

    /** First-time profile setup for the signed-in user. */
    public function store(Request $request)
    {
        $user = $request->user();
        if ($user->hasProfile()) {
            throw ApiError::conflict('Your profile already exists.');
        }
        $data = $request->validate([
            'displayName' => ['required', 'string', 'min:2', 'max:50'],
            'district' => ['required', 'string', 'max:40'],
            'role' => ['required', Rule::in(User::SELF_ROLES)],
            'language' => ['required', Rule::in(['en', 'si', 'ta'])],
            'email' => ['nullable', 'email'],
        ]);

        $user->forceFill([
            'display_name' => trim($data['displayName']),
            'district' => $data['district'],
            'role' => $data['role'],
            'language' => $data['language'],
            'email' => $data['email'] ?? null,
            'badges' => [],
            'profile_completed_at' => now(),
            'last_active_at' => now(),
        ])->save();

        return response()->json($user->fresh()->toApi(), 201);
    }

    /**
     * Self: displayName, district, language, photoUrl, role (donor/requester/both).
     * Admin: also isBanned, role (any), points, badges.
     */
    public function update(Request $request, string $uid)
    {
        $me = $request->user();
        $target = User::find($uid);
        if ($target === null || ! $target->hasProfile()) {
            throw ApiError::notFound('Profile not found.');
        }
        $isSelf = $me->id === $target->id;
        if (! $isSelf && ! $me->isAdmin()) {
            throw ApiError::forbidden();
        }

        $rules = [
            'displayName' => ['sometimes', 'string', 'min:2', 'max:50'],
            'district' => ['sometimes', 'string', 'max:40'],
            'language' => ['sometimes', Rule::in(['en', 'si', 'ta'])],
            'photoUrl' => ['sometimes', 'nullable', 'string', 'max:500'],
            'role' => ['sometimes', Rule::in($me->isAdmin() ? User::ROLES : User::SELF_ROLES)],
        ];
        $adminOnly = ['isBanned', 'points', 'badges'];
        if ($me->isAdmin()) {
            $rules += [
                'isBanned' => ['sometimes', 'boolean'],
                'points' => ['sometimes', 'integer', 'min:0'],
                'badges' => ['sometimes', 'array'],
                'badges.*' => ['string'],
            ];
        } elseif (count(array_intersect($adminOnly, array_keys($request->all()))) > 0) {
            throw ApiError::forbidden('Only an admin can change that.');
        }
        $data = $request->validate($rules);

        if (isset($data['role']) && $target->role === 'admin' && ! $me->isAdmin()) {
            throw ApiError::forbidden('Admins keep their role.');
        }

        $map = [
            'displayName' => 'display_name', 'district' => 'district', 'language' => 'language',
            'photoUrl' => 'photo_url', 'role' => 'role', 'isBanned' => 'is_banned',
            'points' => 'points', 'badges' => 'badges',
        ];
        foreach ($data as $key => $value) {
            if (! isset($map[$key])) {
                continue;
            }
            if ($key === 'displayName') {
                $value = trim($value);
            }
            if ($key === 'photoUrl' && $value !== null) {
                $value = Api::storedFilePath($value);
            }
            $target->{$map[$key]} = $value;
        }
        if ($isSelf) {
            $target->last_active_at = now();
        }
        $target->save();

        return response()->json($target->fresh()->toApi());
    }

    /** All-time top donors. */
    public function leaderboard(Request $request)
    {
        $limit = min(max((int) $request->query('limit', 20), 1), 100);
        $users = User::whereNotNull('profile_completed_at')
            ->orderByDesc('donation_count')->orderBy('created_at')
            ->limit($limit)->get();

        return response()->json($users->map->toApi()->values());
    }

    /** Donors whose last donation was in ?month=2026-10 (defaults to now, UTC). */
    public function monthly(Request $request)
    {
        $key = (string) $request->query('month', User::monthKeyNow());
        $users = User::whereNotNull('profile_completed_at')
            ->where('month_key', $key)
            ->orderByDesc('month_donations')
            ->limit(100)->get();

        return response()->json($users->map->toApi()->values());
    }
}
