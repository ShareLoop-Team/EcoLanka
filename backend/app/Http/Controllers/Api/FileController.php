<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiError;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Photo uploads (replaces Cloudinary / Firebase Storage). Files live on the
 * "public" disk under shareloop/{folder}/ and are served by GET /api/files/…
 * (no `storage:link` symlink needed, which is awkward on Windows).
 */
class FileController extends Controller
{
    public function upload(Request $request)
    {
        $data = $request->validate([
            'file' => ['required', 'file', 'image', 'mimes:jpg,jpeg,png,webp,gif', 'max:5120'],
            'folder' => ['required', 'string', 'regex:/^(items|users|reports)\/[A-Za-z0-9_-]{1,64}$/'],
        ]);
        $user = $request->user();
        if (str_starts_with($data['folder'], 'users/') && $data['folder'] !== 'users/'.$user->id) {
            throw ApiError::forbidden('You can only upload your own profile photo.');
        }

        $file = $request->file('file');
        $ext = strtolower($file->guessExtension() ?: $file->getClientOriginalExtension() ?: 'jpg');
        $path = $file->storeAs('shareloop/'.$data['folder'], Str::random(24).'.'.$ext, 'public');
        $relative = '/api/files/'.$path;

        return response()->json([
            'path' => $relative,
            'url' => rtrim($request->getSchemeAndHttpHost(), '/').$relative,
        ], 201);
    }

    public function show(string $path)
    {
        if (str_contains($path, '..') || ! Storage::disk('public')->exists($path)) {
            abort(404);
        }

        return response()->file(Storage::disk('public')->path($path), [
            'Cache-Control' => 'public, max-age=31536000, immutable',
        ]);
    }
}
