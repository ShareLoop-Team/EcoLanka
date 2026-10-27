<?php

namespace App\Services\Sms;

use Illuminate\Support\Facades\Log;

/** Development driver: writes the SMS to storage/logs/laravel.log instead of sending it. */
class LogSmsSender implements SmsSender
{
    public function send(string $phone, string $message): void
    {
        Log::info("[SMS to {$phone}] {$message}");
    }
}
