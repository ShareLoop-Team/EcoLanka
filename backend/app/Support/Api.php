<?php

namespace App\Support;

use DateTimeInterface;
use Illuminate\Support\Str;

/** Small helpers shared by the API models (dates, file URLs, ids). */
class Api
{
    /** ISO-8601 UTC timestamp, or null. */
    public static function date(?DateTimeInterface $date): ?string
    {
        return $date?->format('Y-m-d\TH:i:s.v\Z');
    }

    /**
     * Uploaded files are stored as a relative path ("/api/files/…") so they keep
     * working whatever host the phone uses (10.0.2.2, LAN IP, localhost…).
     * External URLs (e.g. old Cloudinary photos) pass through unchanged.
     */
    public static function fileUrl(?string $stored): ?string
    {
        if ($stored === null || $stored === '') {
            return $stored;
        }
        if (Str::startsWith($stored, '/')) {
            return rtrim(request()->getSchemeAndHttpHost(), '/').$stored;
        }

        return $stored;
    }

    /** Reverse of fileUrl(): strip our own host so only the path is stored. */
    public static function storedFilePath(string $url): string
    {
        $pos = strpos($url, '/api/files/');
        if ($pos !== false) {
            return substr($url, $pos);
        }

        return $url;
    }

    /** @param  array<int,string>|null  $urls */
    public static function fileUrls(?array $urls): array
    {
        return array_map(fn ($u) => self::fileUrl($u), $urls ?? []);
    }

    /**
     * Anti-resell guardrail — same pattern as the app's AntiResellPolicy.
     */
    public static function looksLikeSale(string $text): bool
    {
        return (bool) preg_match('/(\brs\.?\s*\d|\blkr\b|\bprice\b|for sale|\bselling\b|\bsell\b|\bcash\b|රු|ரூ)/iu', $text);
    }

    public const SALE_MESSAGE = 'Shareloop is for free giving — no prices or sales';
}
