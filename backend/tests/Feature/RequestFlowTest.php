<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Item;
use App\Models\User;

class RequestFlowTest extends ApiTestCase
{
    private function request(User $requester, Item $item, array $extra = [])
    {
        return $this->actingAsUser($requester)->postJson('/api/requests', array_merge([
            'itemId' => $item->id, 'message' => 'I need these for school', 'antiResellAgreed' => true,
        ], $extra));
    }

    public function test_full_exchange(): void
    {
        $donor = $this->makeUser('+94771000001');
        $alice = $this->makeUser('+94771000002');
        $bob = $this->makeUser('+94771000003');
        $item = $this->makeItem($donor);
        $aliceReq = $item->id.'_'.$alice->id;
        $bobReq = $item->id.'_'.$bob->id;

        $this->request($alice, $item, ['requestId' => $aliceReq])->assertCreated()->assertJsonPath('id', $aliceReq);
        $this->request($alice, $item)->assertStatus(409); // one per item per user
        $this->request($bob, $item)->assertCreated();
        $this->assertSame(2, $item->fresh()->request_count);
        $this->assertSame(1, $alice->fresh()->request_count);
        $this->assertSame(2, AppNotification::where('user_id', $donor->id)->where('type', 'new_request')->count());

        // donor sees both; outsiders cannot see a request
        $this->actingAsUser($donor)->getJson("/api/requests?itemId={$item->id}")->assertJsonCount(2);
        $this->getJson('/api/requests?as=donor')->assertJsonCount(2);
        $this->actingAsUser($bob)->getJson("/api/requests/$aliceReq")->assertForbidden();
        $this->actingAsUser($alice)->getJson('/api/requests?as=requester')->assertJsonCount(1);

        // only the donor accepts
        $this->actingAsUser($alice)->postJson("/api/requests/$aliceReq/accept")->assertForbidden();
        $this->actingAsUser($donor)->postJson("/api/requests/$aliceReq/accept")->assertOk()->assertJsonPath('status', 'accepted');
        $this->assertSame('reserved', $item->fresh()->status);
        $this->assertSame('rejected', \App\Models\ShareRequest::find($bobReq)->status);
        $this->assertSame(1, AppNotification::where('user_id', $bob->id)->where('type', 'request_rejected')->count());
        $this->postJson("/api/requests/$aliceReq/accept")->assertStatus(422);

        // handover method — either side, only valid ids
        $this->actingAsUser($alice)->patchJson("/api/requests/$aliceReq/handover", ['handoverMethod' => 'teleport'])->assertStatus(422);
        $this->patchJson("/api/requests/$aliceReq/handover", ['handoverMethod' => 'courier'])->assertOk()->assertJsonPath('handoverMethod', 'courier');

        // reviews only after completion
        $this->postJson('/api/reviews', ['requestId' => $aliceReq, 'rating' => 5])->assertStatus(422);

        $this->actingAsUser($donor)->postJson("/api/requests/$aliceReq/complete")->assertOk()->assertJsonPath('status', 'completed');
        $this->assertSame('donated', $item->fresh()->status);
        $donor->refresh();
        $this->assertSame(1, $donor->donation_count);
        $this->assertSame(1, $donor->month_donations);
        $this->assertSame(User::monthKeyNow(), $donor->month_key);

        // two-way reviews
        $this->actingAsUser($alice)->getJson("/api/reviews/mine?requestId=$aliceReq")->assertJsonPath('exists', false);
        $this->postJson('/api/reviews', ['requestId' => $aliceReq, 'rating' => 4, 'comment' => 'Thanks!'])
            ->assertCreated()->assertJsonPath('revieweeId', $donor->id);
        $this->postJson('/api/reviews', ['requestId' => $aliceReq, 'rating' => 5])->assertStatus(409);
        $this->getJson("/api/reviews/mine?requestId=$aliceReq")->assertJsonPath('exists', true);
        $this->actingAsUser($donor)->postJson('/api/reviews', ['requestId' => $aliceReq, 'rating' => 9])->assertStatus(422);
        $this->postJson('/api/reviews', ['requestId' => $aliceReq, 'rating' => 5])->assertCreated()->assertJsonPath('revieweeId', $alice->id);
        $this->actingAsUser($bob)->postJson('/api/reviews', ['requestId' => $aliceReq, 'rating' => 1])->assertForbidden();
        $this->assertEquals(4.0, $donor->fresh()->rating);
        $this->getJson("/api/reviews?revieweeId={$donor->id}")->assertJsonCount(1);

        // notifications: own only, mark read
        $this->actingAsUser($alice);
        $notes = $this->getJson('/api/notifications')->assertOk()->json();
        $this->assertSame(['request_completed', 'request_accepted'], array_column($notes, 'type'));
        $this->actingAsUser($bob)->postJson("/api/notifications/{$notes[0]['id']}/read")->assertForbidden();
        $this->actingAsUser($alice)->postJson('/api/notifications/read', ['ids' => array_column($notes, 'id')])
            ->assertJsonPath('updated', 2);
    }

    public function test_request_rules(): void
    {
        $donor = $this->makeUser('+94771000001');
        $requester = $this->makeUser('+94771000002');
        $donorOnly = $this->makeUser('+94771000003', 'donor');
        $item = $this->makeItem($donor);

        $this->request($donor, $item)->assertStatus(422); // own item
        $this->request($donorOnly, $item)->assertForbidden(); // role
        $this->request($requester, $item, ['antiResellAgreed' => false])->assertStatus(422);
        $this->request($requester, $item, ['message' => 'pls'])->assertStatus(422);
        $this->request($requester, $item, ['requestId' => 'forged_id'])->assertStatus(422);

        $taken = $this->makeItem($donor, ['status' => 'reserved']);
        $this->request($requester, $taken)->assertStatus(422)->assertJsonPath('code', 'not-available');
    }

    public function test_cancel_and_reject(): void
    {
        $donor = $this->makeUser('+94771000001');
        $requester = $this->makeUser('+94771000002');
        $item = $this->makeItem($donor);
        $id = $item->id.'_'.$requester->id;
        $this->request($requester, $item)->assertCreated();

        $this->actingAsUser($donor)->postJson("/api/requests/$id/cancel")->assertForbidden();
        $this->postJson("/api/requests/$id/accept")->assertOk();
        $this->actingAsUser($requester)->postJson("/api/requests/$id/cancel")->assertOk()->assertJsonPath('status', 'cancelled');
        $this->assertSame('available', $item->fresh()->status); // back on the shelf
        $this->assertSame(1, AppNotification::where('user_id', $donor->id)->where('type', 'request_cancelled')->count());

        $item2 = $this->makeItem($donor);
        $id2 = $item2->id.'_'.$requester->id;
        $this->request($requester, $item2)->assertCreated();
        $this->actingAsUser($donor)->postJson("/api/requests/$id2/reject")->assertOk()->assertJsonPath('status', 'rejected');
        $this->postJson("/api/requests/$id2/complete")->assertStatus(422);
    }

    public function test_reports(): void
    {
        $user = $this->makeUser('+94771000001');
        $admin = $this->makeUser('+94771000002', 'admin');
        $item = $this->makeItem($admin);

        $this->actingAsUser($user)->postJson('/api/reports', ['targetType' => 'item', 'targetId' => $item->id, 'reason' => 'resell', 'details' => 'Asking money'])
            ->assertCreated()->assertJsonPath('id', "item_{$item->id}_{$user->id}");
        $this->postJson('/api/reports', ['targetType' => 'item', 'targetId' => $item->id, 'reason' => 'spam'])->assertStatus(409);
        $this->postJson('/api/reports', ['targetType' => 'car', 'targetId' => 'x', 'reason' => 'spam'])->assertStatus(422);
        $this->getJson('/api/reports')->assertForbidden();

        $this->actingAsUser($admin)->getJson('/api/reports')->assertOk()->assertJsonCount(1);
        $this->patchJson("/api/reports/item_{$item->id}_{$user->id}", ['status' => 'resolved'])->assertOk()->assertJsonPath('status', 'resolved');
    }
}
