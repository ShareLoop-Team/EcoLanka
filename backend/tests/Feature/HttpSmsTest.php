<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;

/** OTP codes sent through httpSMS (an Android phone used as an SMS gateway). */
class HttpSmsTest extends ApiTestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config([
            'otp.local_enabled' => true,
            'otp.test_numbers' => '',
            'otp.sms_driver' => 'httpsms',
            'services.httpsms.url' => 'https://api.httpsms.com',
            'services.httpsms.api_key' => 'test-key',
            'services.httpsms.from' => '+94711111111',
        ]);
    }

    public function test_code_is_sent_through_httpsms_and_works(): void
    {
        Http::fake(['api.httpsms.com/*' => Http::response(['status' => 'success', 'data' => ['id' => 'm1']], 200)]);

        $this->postJson('/api/auth/send-code', ['phone' => '+94771234567'])->assertOk();

        $code = null;
        Http::assertSent(function ($request) use (&$code) {
            preg_match('/\b(\d{6})\b/', $request['content'], $m);
            $code = $m[1] ?? null;

            return $request->url() === 'https://api.httpsms.com/v1/messages/send'
                && $request->hasHeader('X-API-Key', 'test-key')
                && $request['from'] === '+94711111111'
                && $request['to'] === '+94771234567'
                && str_contains($request['content'], 'EcoLanka');
        });
        $this->assertNotNull($code);

        $this->postJson('/api/auth/verify', ['phone' => '+94771234567', 'code' => $code])
            ->assertOk()->assertJsonPath('phone', '+94771234567');
    }

    public function test_offline_phone_gives_a_friendly_error(): void
    {
        Http::fake(['api.httpsms.com/*' => Http::response(['status' => 'error', 'message' => 'phone offline'], 500)]);

        $this->postJson('/api/auth/send-code', ['phone' => '+94771234567'])
            ->assertStatus(503)->assertJsonPath('code', 'sms-failed');
        // the unsent code can't be used
        $this->postJson('/api/auth/verify', ['phone' => '+94771234567', 'code' => '123456'])->assertStatus(422);
    }

    public function test_missing_configuration_is_reported(): void
    {
        config(['services.httpsms.api_key' => null]);
        Http::fake();
        $this->postJson('/api/auth/send-code', ['phone' => '+94771234567'])->assertStatus(503);
        Http::assertNothingSent();
    }

    public function test_test_numbers_skip_sms(): void
    {
        config(['otp.test_numbers' => '+94770000001:123456']);
        Http::fake();
        $this->postJson('/api/auth/send-code', ['phone' => '+94770000001'])->assertOk();
        $this->postJson('/api/auth/verify', ['phone' => '+94770000001', 'code' => '123456'])->assertOk();
        Http::assertNothingSent();
    }
}
