<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // users — one row per phone number. display_name is null until the
        // person finishes profile setup (the app treats that as "no profile").
        Schema::create('users', function (Blueprint $table) {
            $table->string('id', 40)->primary();
            $table->string('phone', 20)->unique();
            $table->string('display_name', 50)->nullable();
            $table->string('email')->nullable();
            $table->string('photo_url', 500)->nullable();
            $table->string('role', 16)->default('both'); // donor | requester | both | admin
            $table->string('language', 4)->default('en'); // en | si | ta
            $table->string('district', 40)->default('Colombo');
            $table->unsignedInteger('points')->default(0);
            $table->json('badges')->nullable();
            $table->unsignedInteger('donation_count')->default(0);
            $table->string('month_key', 8)->nullable(); // "2026-10" (UTC, no zero pad)
            $table->unsignedInteger('month_donations')->default(0);
            $table->unsignedInteger('request_count')->default(0);
            $table->decimal('rating', 3, 2)->default(0);
            $table->boolean('is_banned')->default(false);
            $table->timestamp('profile_completed_at')->nullable();
            $table->timestamp('last_active_at')->nullable();
            $table->timestamps();

            $table->index('donation_count');
            $table->index('month_key');
        });

        Schema::create('otp_codes', function (Blueprint $table) {
            $table->id();
            $table->string('phone', 20)->index();
            $table->string('code_hash');
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('expires_at');
            $table->timestamp('used_at')->nullable();
            $table->timestamps();
        });

        // Sanctum tokens (string morphs because user ids are strings).
        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('tokenable_type');
            $table->string('tokenable_id', 40);
            $table->index(['tokenable_type', 'tokenable_id']);
            $table->text('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable()->index();
            $table->timestamps();
        });

        Schema::create('sessions', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('user_id', 40)->nullable()->index();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->longText('payload');
            $table->integer('last_activity')->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sessions');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('otp_codes');
        Schema::dropIfExists('users');
    }
};
