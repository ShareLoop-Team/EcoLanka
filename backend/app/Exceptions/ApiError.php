<?php

namespace App\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;

/**
 * A friendly API error: {"message": "...", "code": "invalid-code"}.
 * The app shows [message] and uses [code] for special cases.
 */
class ApiError extends Exception
{
    public function __construct(string $message, public string $errorCode = 'error', public int $status = 400)
    {
        parent::__construct($message);
    }

    public static function forbidden(string $message = 'You are not allowed to do this.'): self
    {
        return new self($message, 'permission-denied', 403);
    }

    public static function notFound(string $message = 'Not found.'): self
    {
        return new self($message, 'not-found', 404);
    }

    public static function conflict(string $message, string $code = 'already-exists'): self
    {
        return new self($message, $code, 409);
    }

    public static function invalid(string $message, string $code = 'invalid-argument'): self
    {
        return new self($message, $code, 422);
    }

    public function render(): JsonResponse
    {
        return response()->json(['message' => $this->getMessage(), 'code' => $this->errorCode], $this->status);
    }
}
