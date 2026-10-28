<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // Phone sign-in is done with Firebase Authentication in the app.
    'firebase' => [
        'project_id' => env('FIREBASE_PROJECT_ID', 'shareloop-c2157'),
    ],

    // httpSMS: SMS sent from your own Android phone (app + api.httpsms.com).
    'httpsms' => [
        'url' => env('HTTPSMS_URL', 'https://api.httpsms.com'),
        'api_key' => env('HTTPSMS_API_KEY'),
        'from' => env('HTTPSMS_FROM'),
    ],

    'notifylk' => [
        'user_id' => env('NOTIFYLK_USER_ID'),
        'api_key' => env('NOTIFYLK_API_KEY'),
        'sender_id' => env('NOTIFYLK_SENDER_ID', 'NotifyDEMO'),
    ],

];
