<?php

namespace App\Services\Sms;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * httpSMS — sends the SMS from your own Android phone (https://httpsms.com,
 * https://github.com/NdoleStudio/httpsms). Install the httpSMS app on the
 * phone, sign in, copy the API key from https://httpsms.com/settings.
 *
 *   SMS_DRIVER=httpsms
 *   HTTPSMS_API_KEY=...            # from httpsms.com/settings
 *   HTTPSMS_FROM=+9477xxxxxxx      # the phone number registered in the app
 *   HTTPSMS_URL=https://api.httpsms.com   # or your self-hosted httpSMS API
 */
class HttpSmsSender implements SmsSender
{
    public function send(string $phone, string $message): void
    {
        $cfg = config('services.httpsms');
        if (empty($cfg['api_key']) || empty($cfg['from'])) {
            throw new RuntimeException('httpSMS is not configured: set HTTPSMS_API_KEY and HTTPSMS_FROM in backend/.env');
        }

        $response = Http::baseUrl(rtrim($cfg['url'], '/'))
            ->withHeaders(['X-API-Key' => $cfg['api_key']])
            ->acceptJson()
            ->timeout(20)
            // Use the operating system's certificate store (php.ini often has no CA bundle on Windows).
            ->withOptions(['curl' => [CURLOPT_SSL_OPTIONS => CURLSSLOPT_NATIVE_CA]])
            ->post('/v1/messages/send', [
                'from' => $cfg['from'],
                'to' => $phone,
                'content' => $message,
            ]);

        if (! $response->successful()) {
            throw new RuntimeException("httpSMS error ({$response->status()}): ".($response->json('message') ?? $response->body()));
        }
    }
}
