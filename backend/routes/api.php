<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\FileController;
use App\Http\Controllers\Api\ItemController;
use App\Http\Controllers\Api\NeedController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\ShareRequestController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

// Shareloop / EcoLanka REST API — see backend/README.md for the full reference.

Route::get('/health', fn () => ['ok' => true, 'app' => 'shareloop-api']);

// Public: photos are referenced from Image.network() (no auth header).
Route::get('/files/{path}', [FileController::class, 'show'])->where('path', '.*');

Route::middleware('throttle:otp')->prefix('auth')->group(function () {
    Route::post('/firebase', [AuthController::class, 'firebase']);
    Route::post('/send-code', [AuthController::class, 'sendCode']);
    Route::post('/verify', [AuthController::class, 'verify']);
});

Route::middleware(['auth:sanctum', 'throttle:api'])->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    Route::get('/users/leaderboard', [UserController::class, 'leaderboard']);
    Route::get('/users/monthly', [UserController::class, 'monthly']);
    Route::post('/users', [UserController::class, 'store']);
    Route::get('/users/{uid}', [UserController::class, 'show']);
    Route::patch('/users/{uid}', [UserController::class, 'update']);

    Route::get('/categories', [CategoryController::class, 'index']);

    Route::get('/items', [ItemController::class, 'index']);
    Route::post('/items', [ItemController::class, 'store']);
    Route::get('/items/{id}', [ItemController::class, 'show']);
    Route::patch('/items/{id}/status', [ItemController::class, 'setStatus']);

    Route::get('/needs', [NeedController::class, 'index']);
    Route::post('/needs', [NeedController::class, 'store']);
    Route::get('/needs/{id}', [NeedController::class, 'show']);
    Route::patch('/needs/{id}/status', [NeedController::class, 'setStatus']);
    Route::post('/needs/{id}/match', [NeedController::class, 'notifyMatch']);

    Route::get('/requests', [ShareRequestController::class, 'index']);
    Route::post('/requests', [ShareRequestController::class, 'store']);
    Route::get('/requests/{id}', [ShareRequestController::class, 'show']);
    Route::post('/requests/{id}/accept', [ShareRequestController::class, 'accept']);
    Route::post('/requests/{id}/reject', [ShareRequestController::class, 'reject']);
    Route::post('/requests/{id}/complete', [ShareRequestController::class, 'complete']);
    Route::post('/requests/{id}/cancel', [ShareRequestController::class, 'cancel']);
    Route::patch('/requests/{id}/handover', [ShareRequestController::class, 'setHandover']);

    Route::get('/reviews', [ReviewController::class, 'index']);
    Route::get('/reviews/mine', [ReviewController::class, 'mine']);
    Route::post('/reviews', [ReviewController::class, 'store']);

    Route::get('/reports', [ReportController::class, 'index']);
    Route::post('/reports', [ReportController::class, 'store']);
    Route::patch('/reports/{id}', [ReportController::class, 'update']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/read', [NotificationController::class, 'markAllRead']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markRead']);

    Route::post('/uploads', [FileController::class, 'upload']);
});
