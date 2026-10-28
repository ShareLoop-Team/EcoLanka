<?php

return [
    // The app signs in with Firebase phone auth (POST /api/auth/firebase).
    // Set OTP_LOCAL_ENABLED=true to also allow the API's own SMS codes.
    'local_enabled' => (bool) env('OTP_LOCAL_ENABLED', false),

    'ttl_minutes' => (int) env('OTP_TTL_MINUTES', 5),
    'max_attempts' => (int) env('OTP_MAX_ATTEMPTS', 5),
    'max_per_hour' => (int) env('OTP_MAX_PER_HOUR', 5),

    // "+94770000001:123456,+94770000002:123456" — no SMS is sent for these.
    'test_numbers' => env('OTP_TEST_NUMBERS', ''),

    // Return the code in the send-code response (local development only!).
    'expose_code' => (bool) env('OTP_EXPOSE_CODE', false),

    // log | notifylk
    'sms_driver' => env('SMS_DRIVER', 'log'),
];
