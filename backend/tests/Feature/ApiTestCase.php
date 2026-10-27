<?php

namespace Tests\Feature;

use App\Models\Item;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

abstract class ApiTestCase extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(CategorySeeder::class);
    }

    protected function makeUser(string $phone, string $role = 'both', array $extra = []): User
    {
        return User::create(array_merge([
            'phone' => $phone,
            'display_name' => 'User '.substr($phone, -4),
            'role' => $role,
            'district' => 'Colombo',
            'badges' => [],
            'profile_completed_at' => now(),
        ], $extra));
    }

    protected function actingAsUser(User $user): static
    {
        Sanctum::actingAs($user);

        return $this;
    }

    protected function makeItem(User $donor, array $extra = []): Item
    {
        return Item::create(array_merge([
            'id' => 'item'.uniqid(),
            'donor_id' => $donor->id,
            'title' => 'School books',
            'description' => 'Grade 10 books',
            'category_id' => 'books',
            'condition' => 'good',
            'images' => [],
            'district' => 'Colombo',
            'city' => 'Nugegoda',
            'status' => 'available',
        ], $extra));
    }
}
