<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FilmController;
use App\Http\Controllers\Api\EpisodeController;
use App\Http\Controllers\Api\HistoryController;
use App\Http\Controllers\Api\BookmarkController;
use App\Http\Controllers\Api\CommentController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// ======================
// AUTH (Public)
// ======================
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// ======================
// AUTH (Protected)
// ======================
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
});

// ======================
// FILM (Public)
// ======================
Route::prefix('films')->group(function () {
    Route::get('/', [FilmController::class, 'index']);
    Route::get('/featured', [FilmController::class, 'featured']);
    Route::get('/search', [FilmController::class, 'search']);
    Route::get('/{id}', [FilmController::class, 'show']);
});

// ======================
// EPISODE (Public)
// ======================
Route::get('/episodes/{id}', [EpisodeController::class, 'show']);

// ======================
// COMMENTS (Public Read)
// ======================
Route::get('/films/{filmId}/comments', [CommentController::class, 'index']);

// ======================
// PROTECTED ROUTES (Login Required)
// ======================
Route::middleware('auth:sanctum')->group(function () {

    // ======================
// HISTORY
// ======================
Route::prefix('histories')->group(function () {
    Route::get('/', [HistoryController::class, 'index']);
    Route::post('/', [HistoryController::class, 'store']);
    Route::put('/{id}', [HistoryController::class, 'update']);    // 🔥 TAMBAHKAN
    Route::delete('/{id}', [HistoryController::class, 'destroy']); // 🔥 TAMBAHKAN
});

    // ======================
    // BOOKMARK
    // ======================
    Route::prefix('bookmarks')->group(function () {
        Route::get('/', [BookmarkController::class, 'index']);
        Route::post('/', [BookmarkController::class, 'store']);
        Route::delete('/{film_id}', [BookmarkController::class, 'destroy']);
        Route::get('/check/{film_id}', [BookmarkController::class, 'check']); // Optional: cek status bookmark
    });

    // ======================
    // COMMENTS (Protected)
    // ======================
    Route::prefix('films')->group(function () {
        Route::post('/{filmId}/comments', [CommentController::class, 'store']);
    });
    Route::delete('/comments/{id}', [CommentController::class, 'destroy']);
    Route::put('/comments/{id}', [CommentController::class, 'update']); // Optional: update komentar
});