<?php

namespace App\Services\Sms;

interface SmsSender
{
    /** Sends [message] to an E.164 number (e.g. +94771234567). */
    public function send(string $phone, string $message): void;
}
