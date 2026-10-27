<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class ItemAndNeedTest extends ApiTestCase
{
    private function itemPayload(array $extra = []): array
    {
        return array_merge([
            'id' => 'abcdefgh123456789012',
            'title' => 'Grade 10 books', 'description' => 'Science and maths', 'categoryId' => 'books',
            'condition' => 'good', 'district' => 'Colombo', 'city' => 'Nugegoda', 'images' => [],
        ], $extra);
    }

    public function test_donor_creates_and_lists_items(): void
    {
        $donor = $this->makeUser('+94771000001', 'donor');
        $this->actingAsUser($donor)->postJson('/api/items', $this->itemPayload())
            ->assertCreated()->assertJsonPath('id', 'abcdefgh123456789012')
            ->assertJsonPath('status', 'available')->assertJsonPath('donorId', $donor->id);

        $this->getJson('/api/items')->assertOk()->assertJsonCount(1);
        $this->getJson("/api/items?donorId={$donor->id}")->assertJsonCount(1);
        $this->getJson('/api/items/abcdefgh123456789012')->assertOk()->assertJsonPath('title', 'Grade 10 books');
        $this->postJson('/api/items', $this->itemPayload())->assertStatus(409);
    }

    public function test_item_validation(): void
    {
        $donor = $this->makeUser('+94771000001', 'donor');
        $this->actingAsUser($donor);
        $this->postJson('/api/items', $this->itemPayload(['id' => 'x1234567', 'title' => 'Bike for sale']))
            ->assertStatus(422)->assertJsonPath('code', 'looks-like-sale');
        $this->postJson('/api/items', $this->itemPayload(['id' => 'x1234568', 'condition' => 'broken']))->assertStatus(422);
        $this->postJson('/api/items', $this->itemPayload(['id' => 'x1234569', 'images' => array_fill(0, 6, 'a')]))->assertStatus(422);
        $this->postJson('/api/items', $this->itemPayload(['id' => 'x1234570', 'categoryId' => 'toys']))->assertStatus(422);
    }

    public function test_requester_role_cannot_share(): void
    {
        $r = $this->makeUser('+94771000001', 'requester');
        $this->actingAsUser($r)->postJson('/api/items', $this->itemPayload())->assertForbidden();
    }

    public function test_only_donor_or_admin_changes_item_status(): void
    {
        $donor = $this->makeUser('+94771000001');
        $other = $this->makeUser('+94771000002');
        $admin = $this->makeUser('+94771000003', 'admin');
        $item = $this->makeItem($donor);

        $this->actingAsUser($other)->patchJson("/api/items/{$item->id}/status", ['status' => 'removed'])->assertForbidden();
        $this->actingAsUser($donor)->patchJson("/api/items/{$item->id}/status", ['status' => 'removed'])->assertOk();
        $this->actingAsUser($admin)->patchJson("/api/items/{$item->id}/status", ['status' => 'available'])->assertOk();
        $this->actingAsUser($donor)->patchJson("/api/items/{$item->id}/status", ['status' => 'sold'])->assertStatus(422);
    }

    public function test_needs_and_match_notification(): void
    {
        $requester = $this->makeUser('+94771000001', 'requester');
        $donor = $this->makeUser('+94771000002', 'donor');

        $this->actingAsUser($requester)->postJson('/api/needs', [
            'title' => 'School bag', 'reason' => 'Starting school', 'categoryId' => 'school', 'district' => 'Galle',
        ])->assertStatus(422); // declaration missing

        $needId = $this->postJson('/api/needs', [
            'title' => 'School bag', 'description' => '', 'reason' => 'Starting school', 'categoryId' => 'school',
            'district' => 'Galle', 'city' => '', 'antiResellAgreed' => true,
        ])->assertCreated()->assertJsonPath('status', 'open')->json('id');

        $this->actingAsUser($donor)->postJson('/api/needs', [
            'title' => 'X need', 'reason' => 'because', 'categoryId' => 'school', 'district' => 'Galle', 'antiResellAgreed' => true,
        ])->assertForbidden(); // donor-only role

        $item = $this->makeItem($donor);
        $foreign = $this->makeItem($requester);
        $this->postJson("/api/needs/$needId/match", ['itemId' => $foreign->id])->assertForbidden();
        $this->postJson("/api/needs/$needId/match", ['itemId' => $item->id])->assertCreated();
        $this->assertSame(1, AppNotification::where('user_id', $requester->id)->where('type', 'need_match')->count());

        $this->patchJson("/api/needs/$needId/status", ['status' => 'closed'])->assertForbidden();
        $this->actingAsUser($requester)->patchJson("/api/needs/$needId/status", ['status' => 'fulfilled'])
            ->assertOk()->assertJsonPath('status', 'fulfilled');
        $this->getJson("/api/needs?requesterId={$requester->id}")->assertJsonCount(1);
    }

    public function test_photo_upload_and_download(): void
    {
        Storage::fake('public');
        $user = $this->makeUser('+94771000001');
        $this->actingAsUser($user);

        $res = $this->post('/api/uploads', [
            'file' => UploadedFile::fake()->image('photo.jpg', 200, 200),
            'folder' => 'items/abcdefgh',
        ], ['Accept' => 'application/json'])->assertCreated();
        $path = $res->json('path');
        $this->assertStringStartsWith('/api/files/shareloop/items/abcdefgh/', $path);
        $this->assertStringStartsWith('http://', $res->json('url'));
        $this->get($path)->assertOk();

        $this->post('/api/uploads', [
            'file' => UploadedFile::fake()->image('photo.jpg'), 'folder' => 'users/someoneelse',
        ], ['Accept' => 'application/json'])->assertForbidden();

        // the full URL is stored as a relative path and returned absolute again
        $this->postJson('/api/items', [
            'title' => 'Lamp', 'description' => 'Desk lamp', 'categoryId' => 'household', 'condition' => 'good',
            'district' => 'Colombo', 'images' => [$res->json('url')],
        ])->assertCreated()->assertJsonPath('images.0', $res->json('url'));
        $this->get('/api/files/../../.env')->assertNotFound();
    }
}
