<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Support\Facades\Log;

/** The API's own SMS codes (optional; the app uses Firebase — see FirebaseAuthTest). */
class AuthTest extends ApiTestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['otp.local_enabled' => true]);
    }

    public function test_local_codes_are_off_by_default(): void
    {
        config(['otp.local_enabled' => false]);
        $this->postJson('/api/auth/send-code', ['phone' => '+94771234567'])
            ->assertStatus(410)->assertJsonPath('code', 'use-firebase');
    }

    public function test_rejects_invalid_phone(): void
    {
        $this->postJson('/api/auth/send-code', ['phone' => '+9412'])
            ->assertStatus(422)->assertJsonPath('code', 'invalid-argument');
    }

    public function test_otp_flow_with_real_code(): void
    {
        config(['otp.expose_code' => true, 'otp.test_numbers' => '']);
        Log::spy();

        $code = $this->postJson('/api/auth/send-code', ['phone' => '+94771234567'])
            ->assertOk()->json('debugCode');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);
        Log::shouldHaveReceived('info')->withArgs(fn ($m) => str_contains($m, $code))->once();

        $wrong = $code === '000000' ? '111111' : '000000';
        $this->postJson('/api/auth/verify', ['phone' => '+94771234567', 'code' => $wrong])
            ->assertStatus(422)->assertJsonPath('code', 'invalid-verification-code');

        $res = $this->postJson('/api/auth/verify', ['phone' => '+94771234567', 'code' => $code])
            ->assertOk()->assertJsonPath('hasProfile', false);
        $token = $res->json('token');

        // code is single-use
        $this->postJson('/api/auth/verify', ['phone' => '+94771234567', 'code' => $code])->assertStatus(422);

        $this->withToken($token)->getJson('/api/auth/me')
            ->assertOk()->assertJsonPath('phone', '+94771234567');
    }

    public function test_code_is_not_exposed_by_default(): void
    {
        config(['otp.expose_code' => false, 'otp.test_numbers' => '']);
        $this->postJson('/api/auth/send-code', ['phone' => '+94771234567'])
            ->assertOk()->assertJsonMissingPath('debugCode');
    }

    public function test_test_numbers_and_profile_setup(): void
    {
        config(['otp.test_numbers' => '+94770000001:123456']);
        $this->postJson('/api/auth/send-code', ['phone' => '+94770000001'])->assertOk();
        $res = $this->postJson('/api/auth/verify', ['phone' => '+94770000001', 'code' => '123456'])->assertOk();
        $token = $res->json('token');
        $uid = $res->json('uid');

        $this->withToken($token)->getJson("/api/users/$uid")->assertNotFound();

        $this->withToken($token)->postJson('/api/users', [
            'displayName' => 'Nimal', 'district' => 'Kandy', 'role' => 'admin', 'language' => 'en',
        ])->assertStatus(422); // cannot pick admin

        $this->withToken($token)->postJson('/api/users', [
            'displayName' => 'Nimal', 'district' => 'Kandy', 'role' => 'donor', 'language' => 'si',
        ])->assertCreated()->assertJsonPath('displayName', 'Nimal')->assertJsonPath('donationCount', 0);

        $this->withToken($token)->getJson("/api/users/$uid")->assertOk()->assertJsonPath('district', 'Kandy');
    }

    public function test_too_many_codes_are_throttled(): void
    {
        config(['otp.max_per_hour' => 2, 'otp.test_numbers' => '']);
        $this->postJson('/api/auth/send-code', ['phone' => '+94771111111'])->assertOk();
        $this->postJson('/api/auth/send-code', ['phone' => '+94771111111'])->assertOk();
        $this->postJson('/api/auth/send-code', ['phone' => '+94771111111'])
            ->assertStatus(429)->assertJsonPath('code', 'too-many-requests');
    }

    public function test_protected_routes_need_a_token(): void
    {
        $this->getJson('/api/items')->assertUnauthorized()->assertJsonPath('code', 'unauthenticated');
    }

    public function test_logout_revokes_token(): void
    {
        config(['otp.test_numbers' => '+94770000001:123456']);
        $token = $this->postJson('/api/auth/verify', ['phone' => '+94770000001', 'code' => '123456'])->json('token');
        $this->withToken($token)->postJson('/api/auth/logout')->assertOk();
        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/auth/me')->assertUnauthorized();
        $this->assertSame(1, User::count());
    }
}
