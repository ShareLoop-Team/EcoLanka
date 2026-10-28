<?php

return [
    // The API sends and checks its own SMS codes (SMS_DRIVER). Set
    // OTP_LOCAL_ENABLED=false if the app signs in with Firebase only.
    'local_enabled' => (bool) env('OTP_LOCAL_ENABLED', true),

    'ttl_minutes' => (int) env('OTP_TTL_MINUTES', 5),
    'max_attempts' => (int) env('OTP_MAX_ATTEMPTS', 5),
    'max_per_hour' => (int) env('OTP_MAX_PER_HOUR', 5),

    // "+94770000001:123456,+94770000002:123456" — no SMS is sent for these.
    'test_numbers' => env('OTP_TEST_NUMBERS', ''),

    // Return the code in the send-code response (local development only!).
    'expose_code' => (bool) env('OTP_EXPOSE_CODE', false),

    // log | httpsms | notifylk
    'sms_driver' => env('SMS_DRIVER', 'log'),
];
