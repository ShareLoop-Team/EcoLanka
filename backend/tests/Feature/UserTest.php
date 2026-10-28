<?php

namespace Tests\Feature;

class UserTest extends ApiTestCase
{
    public function test_user_can_edit_own_profile_but_not_counters(): void
    {
        $me = $this->makeUser('+94771000001');
        $this->actingAsUser($me);

        $this->patchJson("/api/users/{$me->id}", ['displayName' => 'New Name', 'role' => 'requester'])
            ->assertOk()->assertJsonPath('displayName', 'New Name')->assertJsonPath('role', 'requester');

        $this->patchJson("/api/users/{$me->id}", ['isBanned' => false])->assertForbidden();
        $this->patchJson("/api/users/{$me->id}", ['role' => 'admin'])->assertStatus(422);
        // unknown fields such as counters are ignored
        $this->patchJson("/api/users/{$me->id}", ['donationCount' => 99])->assertOk()->assertJsonPath('donationCount', 0);
    }

    public function test_cannot_edit_someone_else(): void
    {
        $me = $this->makeUser('+94771000001');
        $other = $this->makeUser('+94771000002');
        $this->actingAsUser($me)->patchJson("/api/users/{$other->id}", ['displayName' => 'Hacked'])->assertForbidden();
    }

    public function test_admin_can_ban(): void
    {
        $admin = $this->makeUser('+94771000001', 'admin');
        $other = $this->makeUser('+94771000002');
        $this->actingAsUser($admin)->patchJson("/api/users/{$other->id}", ['isBanned' => true])
            ->assertOk()->assertJsonPath('isBanned', true);
        $this->actingAsUser($other->fresh())->postJson('/api/items', [
            'title' => 'Books', 'description' => 'x', 'categoryId' => 'books', 'condition' => 'good', 'district' => 'Colombo',
        ])->assertForbidden();
    }

    public function test_leaderboards(): void
    {
        $a = $this->makeUser('+94771000001', 'both', ['donation_count' => 3, 'month_key' => now('UTC')->format('Y-n'), 'month_donations' => 2]);
        $b = $this->makeUser('+94771000002', 'both', ['donation_count' => 7, 'month_key' => '2020-1', 'month_donations' => 5]);
        $this->actingAsUser($a);
        $this->getJson('/api/users/leaderboard')->assertOk()->assertJsonPath('0.uid', $b->id);
        $this->getJson('/api/users/monthly')->assertOk()->assertJsonCount(1)->assertJsonPath('0.uid', $a->id);
    }
}
