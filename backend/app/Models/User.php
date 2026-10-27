<?php

namespace App\Models;

use App\Support\Api;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasUlids;

    public const SELF_ROLES = ['donor', 'requester', 'both'];
    public const ROLES = ['donor', 'requester', 'both', 'admin'];

    protected $guarded = [];

    protected $hidden = [];

    protected function casts(): array
    {
        return [
            'badges' => 'array',
            'is_banned' => 'boolean',
            'rating' => 'float',
            'points' => 'integer',
            'donation_count' => 'integer',
            'month_donations' => 'integer',
            'request_count' => 'integer',
            'profile_completed_at' => 'datetime',
            'last_active_at' => 'datetime',
        ];
    }

    public function hasProfile(): bool
    {
        return $this->profile_completed_at !== null;
    }

    public function isAdmin(): bool
    {
        return $this->hasProfile() && $this->role === 'admin';
    }

    public function canDonate(): bool
    {
        return $this->hasProfile() && ! $this->is_banned && in_array($this->role, ['donor', 'both', 'admin'], true);
    }

    public function canRequest(): bool
    {
        return $this->hasProfile() && ! $this->is_banned && in_array($this->role, ['requester', 'both', 'admin'], true);
    }

    /** "2026-10" style key for the current UTC month (matches AppUser.monthKeyFor in the app). */
    public static function monthKeyNow(): string
    {
        return now('UTC')->format('Y-n');
    }

    /** One more completed donation: all-time and monthly counters. */
    public function recordDonation(): void
    {
        $key = self::monthKeyNow();
        $this->month_donations = $this->month_key === $key ? $this->month_donations + 1 : 1;
        $this->month_key = $key;
        $this->donation_count++;
        $this->save();
    }

    public function toApi(): array
    {
        return [
            'uid' => $this->id,
            'displayName' => $this->display_name ?? '',
            'phone' => $this->phone,
            'email' => $this->email,
            'photoUrl' => Api::fileUrl($this->photo_url),
            'role' => $this->role,
            'language' => $this->language,
            'district' => $this->district,
            'points' => $this->points,
            'badges' => $this->badges ?? [],
            'donationCount' => $this->donation_count,
            'requestCount' => $this->request_count,
            'rating' => round((float) $this->rating, 2),
            'isBanned' => $this->is_banned,
            'monthKey' => $this->month_key,
            'monthDonations' => $this->month_donations,
            'createdAt' => Api::date($this->created_at),
            'lastActiveAt' => Api::date($this->last_active_at),
        ];
    }
}
