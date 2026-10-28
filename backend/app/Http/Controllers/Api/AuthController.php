<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\FirebaseTokenVerifier;
use App\Services\OtpService;
use Illuminate\Http\Request;

/**
 * Sign-in. The app verifies the phone number with Firebase Authentication and
 * exchanges the Firebase ID token for a Sanctum bearer token (POST /auth/firebase).
 * The API's own SMS codes (send-code / verify) are off unless OTP_LOCAL_ENABLED=true.
 */
class AuthController extends Controller
{
    private const PHONE_RULE = ['required', 'string', 'regex:/^\+947[01245678]\d{7}$/'];

    public function __construct(private OtpService $otp) {}

    /** Exchange a Firebase phone-auth ID token for an API token. */
    public function firebase(Request $request, FirebaseTokenVerifier $verifier)
    {
        $data = $request->validate(['idToken' => ['required', 'string', 'max:4096']]);
        $claims = $verifier->verify($data['idToken']);

        $phone = $claims['phone_number'] ?? null;
        if (! is_string($phone) || ! preg_match('/^\+947[01245678]\d{7}$/', $phone)) {
            throw ApiError::invalid('Sign in with a Sri Lankan mobile number.', 'invalid-phone-number');
        }

        $user = User::where('firebase_uid', $claims['sub'])->first()
            ?? User::firstOrCreate(['phone' => $phone]);
        $user->forceFill(['firebase_uid' => $claims['sub'], 'phone' => $phone, 'last_active_at' => now()])->save();

        return $this->session($user);
    }

    public function sendCode(Request $request)
    {
        $this->requireLocalOtp();
        $data = $request->validate(['phone' => self::PHONE_RULE], [
            'phone.regex' => 'That phone number is not valid.',
        ]);
        $debugCode = $this->otp->send($data['phone']);

        return response()->json(array_filter([
            'sent' => true,
            'debugCode' => $debugCode,
        ], fn ($v) => $v !== null));
    }

    public function verify(Request $request)
    {
        $this->requireLocalOtp();
        $data = $request->validate([
            'phone' => self::PHONE_RULE,
            'code' => ['required', 'digits:6'],
        ], ['phone.regex' => 'That phone number is not valid.', 'code.digits' => 'Enter the 6-digit code from the SMS.']);

        $this->otp->verify($data['phone'], $data['code']);

        $user = User::firstOrCreate(['phone' => $data['phone']]);
        $user->forceFill(['last_active_at' => now()])->save();

        return $this->session($user);
    }

    private function session(User $user)
    {
        return response()->json([
            'token' => $user->createToken('app')->plainTextToken,
            'uid' => $user->id,
            'phone' => $user->phone,
            'hasProfile' => $user->hasProfile(),
        ]);
    }

    private function requireLocalOtp(): void
    {
        if (! config('otp.local_enabled')) {
            throw new ApiError('Phone sign-in uses Firebase. Update the app.', 'use-firebase', 410);
        }
    }

    public function me(Request $request)
    {
        $user = $request->user();

        return response()->json(['uid' => $user->id, 'phone' => $user->phone, 'hasProfile' => $user->hasProfile()]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['ok' => true]);
    }
}
