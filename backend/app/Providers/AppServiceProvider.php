<?php

namespace App\Providers;

use App\Services\Sms\LogSmsSender;
use App\Services\Sms\NotifyLkSmsSender;
use App\Services\Sms\SmsSender;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(SmsSender::class, fn () => match (config('otp.sms_driver')) {
            'notifylk' => new NotifyLkSmsSender,
            default => new LogSmsSender,
        });
    }

    public function boot(): void
    {
        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(240)->by($request->user()?->id ?: $request->ip()));
        RateLimiter::for('otp', fn (Request $request) => Limit::perMinute(10)->by($request->ip()));
    }
}
