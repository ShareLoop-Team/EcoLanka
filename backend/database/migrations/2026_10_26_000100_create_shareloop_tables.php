<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Shareloop domain tables — same shape as the old Firestore collections
// (see docs/SCHEMA.md). Ids are strings so the app's id conventions stay:
//   requests: {itemId}_{requesterId}
//   reviews:  {requestId}_{reviewerId}
//   reports:  {targetType}_{targetId}_{reporterId}
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->string('id', 32)->primary();
            $table->json('name'); // {en, si, ta}
            $table->string('icon', 40);
            $table->unsignedSmallInteger('order')->default(0);
            $table->timestamps();
        });

        Schema::create('items', function (Blueprint $table) {
            $table->string('id', 64)->primary();
            $table->string('donor_id', 40)->index();
            $table->string('title', 80);
            $table->text('description');
            $table->string('category_id', 32);
            $table->string('condition', 10); // new | good | used
            $table->json('images')->nullable();
            $table->string('district', 40);
            $table->string('city', 80)->default('');
            $table->string('status', 12)->default('available'); // available | reserved | donated | removed
            $table->unsignedInteger('request_count')->default(0);
            $table->timestamps();

            $table->foreign('donor_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index('created_at');
        });

        Schema::create('needs', function (Blueprint $table) {
            $table->string('id', 40)->primary();
            $table->string('requester_id', 40)->index();
            $table->string('title', 80);
            $table->text('description');
            $table->string('reason', 500);
            $table->string('category_id', 32);
            $table->string('district', 40);
            $table->string('city', 80)->default('');
            $table->string('status', 12)->default('open'); // open | fulfilled | closed
            $table->boolean('anti_resell_agreed')->default(true);
            $table->timestamps();

            $table->foreign('requester_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index('created_at');
        });

        Schema::create('share_requests', function (Blueprint $table) {
            $table->string('id', 110)->primary();
            $table->string('item_id', 64)->index();
            $table->string('item_title', 80);
            $table->string('donor_id', 40)->index();
            $table->string('requester_id', 40)->index();
            $table->string('message', 500);
            $table->boolean('anti_resell_agreed')->default(false);
            $table->string('handover_method', 16)->nullable(); // direct | courier | on_demand
            $table->string('status', 12)->default('pending'); // pending | accepted | rejected | cancelled | completed
            $table->timestamps();

            $table->foreign('item_id')->references('id')->on('items')->cascadeOnDelete();
        });

        Schema::create('reviews', function (Blueprint $table) {
            $table->string('id', 160)->primary();
            $table->string('request_id', 110)->index();
            $table->string('reviewer_id', 40);
            $table->string('reviewee_id', 40)->index();
            $table->unsignedTinyInteger('rating');
            $table->string('comment', 500)->default('');
            $table->timestamps();
        });

        Schema::create('reports', function (Blueprint $table) {
            $table->string('id', 160)->primary();
            $table->string('reporter_id', 40)->index();
            $table->string('target_type', 8); // user | item
            $table->string('target_id', 64);
            $table->string('reason', 16); // spam | resell | fraud | inappropriate | other
            $table->string('details', 500)->default('');
            $table->json('evidence')->nullable();
            $table->string('status', 12)->default('open'); // open | reviewing | resolved | dismissed
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->string('id', 40)->primary();
            $table->string('user_id', 40)->index(); // recipient
            $table->string('sender_id', 40)->nullable();
            $table->string('type', 24);
            $table->string('title', 120);
            $table->string('body', 300);
            $table->string('request_id', 110)->nullable();
            $table->string('item_id', 64)->nullable();
            $table->string('need_id', 40)->nullable();
            $table->boolean('read')->default(false);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        foreach (['notifications', 'reports', 'reviews', 'share_requests', 'needs', 'items', 'categories'] as $t) {
            Schema::dropIfExists($t);
        }
    }
};
