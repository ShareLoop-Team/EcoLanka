<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\FirebaseTokenVerifier;

/** Firebase phone sign-in: the app sends Firebase's ID token, the API checks it. */
class FirebaseAuthTest extends ApiTestCase
{
    // Fixed test keys (key generation needs openssl.cnf, often missing on Windows PHP).
    private string $key;

    private string $otherKey;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.firebase.project_id' => 'shareloop-test']);
        $dir = base_path('tests/fixtures/firebase');
        $this->key = file_get_contents("$dir/signing-key.pem");
        $this->otherKey = file_get_contents("$dir/other-key.pem");
        $pem = file_get_contents("$dir/signing-cert.pem");
        $this->app->instance(FirebaseTokenVerifier::class, new FirebaseTokenVerifier(fn () => ['kid1' => $pem]));
    }

    private function token(array $claims = [], ?string $key = null, string $kid = 'kid1'): string
    {
        $b64 = fn ($v) => rtrim(strtr(base64_encode(json_encode($v)), '+/', '-_'), '=');
        $now = time();
        $claims = array_merge([
            'iss' => 'https://securetoken.google.com/shareloop-test',
            'aud' => 'shareloop-test',
            'sub' => 'firebase-uid-1',
            'iat' => $now,
            'exp' => $now + 3600,
            'phone_number' => '+94770000001',
        ], $claims);
        $data = $b64(['alg' => 'RS256', 'kid' => $kid, 'typ' => 'JWT']).'.'.$b64($claims);
        openssl_sign($data, $sig, $key ?? $this->key, OPENSSL_ALGO_SHA256);

        return $data.'.'.rtrim(strtr(base64_encode($sig), '+/', '-_'), '=');
    }

    public function test_valid_token_signs_in_and_links_existing_profile(): void
    {
        $nimal = $this->makeUser('+94770000001');

        $res = $this->postJson('/api/auth/firebase', ['idToken' => $this->token()])
            ->assertOk()->assertJsonPath('uid', $nimal->id)->assertJsonPath('hasProfile', true);
        $this->assertSame('firebase-uid-1', $nimal->fresh()->firebase_uid);

        $this->app['auth']->forgetGuards();
        $this->withToken($res->json('token'))->getJson('/api/auth/me')
            ->assertOk()->assertJsonPath('phone', '+94770000001');
    }

    public function test_new_phone_creates_account_without_profile(): void
    {
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token(['phone_number' => '+94771234567', 'sub' => 'new-uid'])])
            ->assertOk()->assertJsonPath('hasProfile', false)->assertJsonPath('phone', '+94771234567');
        $this->assertSame(1, User::where('firebase_uid', 'new-uid')->count());
    }

    public function test_rejects_forged_or_wrong_tokens(): void
    {
        $this->postJson('/api/auth/firebase', ['idToken' => 'not-a-jwt'])->assertStatus(401);
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token([], $this->otherKey)])
            ->assertStatus(401)->assertJsonPath('code', 'invalid-id-token');
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token([], null, 'unknown-kid')])->assertStatus(401);
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token(['aud' => 'another-project'])])->assertStatus(401);
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token(['iss' => 'https://evil.example'])])->assertStatus(401);
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token(['exp' => time() - 3600])])->assertStatus(401);
        $this->assertSame(0, User::count());
    }

    public function test_requires_a_sri_lankan_phone_number(): void
    {
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token(['phone_number' => '+15555550100'])])
            ->assertStatus(422)->assertJsonPath('code', 'invalid-phone-number');
        $this->postJson('/api/auth/firebase', ['idToken' => $this->token(['phone_number' => null])])->assertStatus(422);
    }
}
