<?php

namespace App\Services\Sms;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Notify.lk (Sri Lankan SMS gateway) — https://developer.notify.lk
 * Set SMS_DRIVER=notifylk and NOTIFYLK_USER_ID / NOTIFYLK_API_KEY / NOTIFYLK_SENDER_ID.
 */
class NotifyLkSmsSender implements SmsSender
{
    public function send(string $phone, string $message): void
    {
        $cfg = config('services.notifylk');
        $response = Http::asForm()->timeout(15)->post('https://app.notify.lk/api/v1/send', [
            'user_id' => $cfg['user_id'],
            'api_key' => $cfg['api_key'],
            'sender_id' => $cfg['sender_id'],
            'to' => ltrim($phone, '+'), // 94771234567
            'message' => $message,
        ]);
        if (! $response->successful() || $response->json('status') !== 'success') {
            throw new RuntimeException('SMS gateway error: '.$response->body());
        }
    }
}
