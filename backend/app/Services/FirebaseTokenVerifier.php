<?php

namespace App\Services;

use App\Exceptions\ApiError;
use Closure;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

/**
 * Verifies a Firebase Authentication ID token (phone sign-in happens in the
 * app with Firebase; the API only trusts the signed token).
 * https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
 */
class FirebaseTokenVerifier
{
    private const CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

    private const LEEWAY = 300; // seconds of clock skew allowed

    /** @param  Closure():array<string,string>|null  $certs  kid → PEM certificate (tests inject their own) */
    public function __construct(private ?Closure $certs = null) {}

    /** @return array<string, mixed> the verified claims */
    public function verify(string $idToken): array
    {
        $projectId = (string) config('services.firebase.project_id');
        if ($projectId === '') {
            throw new ApiError('FIREBASE_PROJECT_ID is not set on the server.', 'server-misconfigured', 500);
        }

        $parts = explode('.', $idToken);
        if (count($parts) !== 3) {
            $this->invalid();
        }
        [$h, $p, $s] = $parts;
        $header = json_decode($this->b64($h), true);
        $claims = json_decode($this->b64($p), true);
        $signature = $this->b64($s);
        if (! is_array($header) || ! is_array($claims) || ($header['alg'] ?? '') !== 'RS256' || empty($header['kid'])) {
            $this->invalid();
        }

        $cert = $this->certificates()[$header['kid']] ?? null;
        if ($cert === null || openssl_verify("$h.$p", $signature, $cert, OPENSSL_ALGO_SHA256) !== 1) {
            $this->invalid();
        }

        $now = time();
        $ok = ($claims['aud'] ?? null) === $projectId
            && ($claims['iss'] ?? null) === "https://securetoken.google.com/$projectId"
            && is_string($claims['sub'] ?? null) && $claims['sub'] !== ''
            && (int) ($claims['exp'] ?? 0) > $now - self::LEEWAY
            && (int) ($claims['iat'] ?? PHP_INT_MAX) <= $now + self::LEEWAY;
        if (! $ok) {
            throw new ApiError('Your sign-in expired. Please sign in again.', 'invalid-id-token', 401);
        }

        return $claims;
    }

    /** @return array<string, string> */
    private function certificates(): array
    {
        if ($this->certs) {
            return ($this->certs)();
        }

        return Cache::remember('firebase.securetoken.certs', now()->addHour(), function () {
            $response = Http::timeout(15)
                // Use the operating system's certificate store (php.ini often has no CA bundle on Windows).
                ->withOptions(['curl' => [CURLOPT_SSL_OPTIONS => CURLSSLOPT_NATIVE_CA]])
                ->get(self::CERTS_URL);
            if (! $response->successful()) {
                throw new ApiError('Could not reach Google to check the sign-in. Try again.', 'certs-unavailable', 503);
            }

            return $response->json();
        });
    }

    private function b64(string $s): string
    {
        return (string) base64_decode(strtr($s, '-_', '+/').str_repeat('=', (4 - strlen($s) % 4) % 4));
    }

    private function invalid(): never
    {
        throw new ApiError('Sign-in could not be verified. Please try again.', 'invalid-id-token', 401);
    }
}
