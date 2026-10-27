<?php

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // The API always answers JSON: {"message": "...", "code": "..."}.
        $exceptions->shouldRenderJsonWhen(fn (Request $request) => $request->is('api/*') || $request->expectsJson());

        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json(['message' => 'Please sign in again.', 'code' => 'unauthenticated'], 401);
            }
        });
        $exceptions->render(function (ValidationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => collect($e->errors())->flatten()->first() ?? $e->getMessage(),
                    'code' => 'invalid-argument',
                    'errors' => $e->errors(),
                ], $e->status);
            }
        });
        $exceptions->render(function (HttpExceptionInterface $e, Request $request) {
            if ($request->is('api/*')) {
                $code = match ($e->getStatusCode()) {
                    404 => 'not-found', 429 => 'too-many-requests', 403 => 'permission-denied', default => 'error',
                };
                $message = match ($e->getStatusCode()) {
                    404 => 'Not found.', 429 => 'Too many attempts. Please wait a while and try again.',
                    default => $e->getMessage() ?: 'Something went wrong.',
                };

                return response()->json(['message' => $message, 'code' => $code], $e->getStatusCode());
            }
        });
    })->create();
