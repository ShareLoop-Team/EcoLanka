<?php

namespace App\Services;

use App\Models\OtpCode;
use App\Services\Sms\SmsSender;
use App\Exceptions\ApiError;
use Illuminate\Support\Facades\Hash;
use Throwable;

/**
 * Phone OTP sign-in (replaces Firebase phone auth).
 *  - 6-digit code, valid for OTP_TTL_MINUTES, max OTP_MAX_ATTEMPTS guesses.
 *  - OTP_TEST_NUMBERS: fixed codes that never send an SMS (for demos / QA).
 */
class OtpService
{
    public function __construct(private SmsSender $sms) {}

    /** @return string|null the code when it may be shown to the developer (debug only) */
    public function send(string $phone): ?string
    {
        $test = $this->testCode($phone);
        if ($test !== null) {
            return config('otp.expose_code') ? $test : null;
        }

        $sentLastHour = OtpCode::where('phone', $phone)->where('created_at', '>', now()->subHour())->count();
        if ($sentLastHour >= config('otp.max_per_hour')) {
            throw new ApiError('Too many attempts. Please wait a while and try again.', 'too-many-requests', 429);
        }

        $code = (string) random_int(100000, 999999);
        OtpCode::where('phone', $phone)->whereNull('used_at')->update(['used_at' => now()]);
        OtpCode::create([
            'phone' => $phone,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(config('otp.ttl_minutes')),
        ]);
        try {
            $this->sms->send($phone, "Your EcoLanka code is {$code}. It expires in ".config('otp.ttl_minutes').' minutes. Do not share it with anyone.');
        } catch (Throwable $e) {
            // e.g. the httpSMS phone is offline — don't leave an unusable code behind.
            report($e);
            OtpCode::where('phone', $phone)->whereNull('used_at')->update(['used_at' => now()]);
            throw new ApiError('We could not send the SMS right now. Please try again in a minute.', 'sms-failed', 503);
        }

        return config('otp.expose_code') ? $code : null;
    }

    /** Throws an ApiError with a friendly message when the code is wrong. */
    public function verify(string $phone, string $code): void
    {
        $test = $this->testCode($phone);
        if ($test !== null) {
            if (! hash_equals($test, $code)) {
                $this->invalid();
            }

            return;
        }

        $otp = OtpCode::where('phone', $phone)->whereNull('used_at')->latest('id')->first();
        if ($otp === null) {
            throw new ApiError('Request a verification code first.', 'no-code', 422);
        }
        if ($otp->expires_at->isPast()) {
            throw new ApiError('The code expired. Please request a new one.', 'code-expired', 422);
        }
        if ($otp->attempts >= config('otp.max_attempts')) {
            throw new ApiError('Too many attempts. Please request a new code.', 'too-many-requests', 429);
        }
        if (! Hash::check($code, $otp->code_hash)) {
            $otp->increment('attempts');
            $this->invalid();
        }
        $otp->update(['used_at' => now()]);
    }

    private function invalid(): never
    {
        throw new ApiError('Incorrect code. Please check and try again.', 'invalid-verification-code', 422);
    }

    private function testCode(string $phone): ?string
    {
        foreach (array_filter(explode(',', (string) config('otp.test_numbers'))) as $pair) {
            [$number, $code] = array_pad(explode(':', trim($pair), 2), 2, null);
            if ($number === $phone && $code) {
                return $code;
            }
        }

        return null;
    }
}
