<?php

use App\Models\User;
use Illuminate\Support\Facades\Artisan;

// php artisan shareloop:make-admin +94771234567
Artisan::command('shareloop:make-admin {phone}', function (string $phone) {
    $user = User::where('phone', $phone)->first();
    if (! $user || ! $user->hasProfile()) {
        $this->error('No completed profile for that phone number. Sign in with the app first.');

        return 1;
    }
    $user->update(['role' => 'admin']);
    $this->info("{$user->display_name} is now an admin.");
})->purpose('Give a user the admin (moderator) role');
