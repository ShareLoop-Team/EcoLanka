<?php

use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json([
    'app' => 'Shareloop (EcoLanka) API',
    'health' => url('/api/health'),
    'docs' => 'backend/README.md',
]));
