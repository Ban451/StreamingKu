<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bookmark;
use App\Models\Film;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BookmarkController extends Controller
{
    /**
     * Get all bookmarks
     * GET /api/bookmarks
     */
    public function index(Request $request)
    {
        $bookmarks = Bookmark::where('user_id', $request->user()->id)
            ->with('film')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $bookmarks
        ]);
    }

    /**
     * Check if film is bookmarked
     * GET /api/bookmarks/check/{film_id}
     */
    public function check($filmId, Request $request)
    {
        $bookmark = Bookmark::where('user_id', $request->user()->id)
            ->where('film_id', $filmId)
            ->exists();

        return response()->json([
            'status' => 'success',
            'data' => [
                'is_bookmarked' => $bookmark
            ]
        ]);
    }

    /**
     * Add bookmark
     * POST /api/bookmarks
     */
    public function store(Request $request)
    {
        $request->validate([
            'film_id' => 'required|exists:films,id',
        ]);

        $film = Film::find($request->film_id);
        if (!$film) {
            return response()->json([
                'status' => 'error',
                'message' => 'Film tidak ditemukan'
            ], 404);
        }

        // Cek apakah sudah di-bookmark
        $existingBookmark = Bookmark::where('user_id', Auth::id())
            ->where('film_id', $request->film_id)
            ->first();

        if ($existingBookmark) {
            return response()->json([
                'status' => 'error',
                'message' => 'Film sudah ada di bookmark'
            ], 409);
        }

        try {
            $bookmark = Bookmark::create([
                'user_id' => Auth::id(),
                'film_id' => $request->film_id,
            ]);

            $bookmark->load('film');

            return response()->json([
                'status' => 'success',
                'message' => 'Bookmark berhasil ditambahkan',
                'data' => $bookmark
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menambahkan bookmark: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove bookmark
     * DELETE /api/bookmarks/{film_id}
     */
    public function destroy($filmId, Request $request)
    {
        $bookmark = Bookmark::where('user_id', $request->user()->id)
            ->where('film_id', $filmId)
            ->first();

        if (!$bookmark) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bookmark tidak ditemukan'
            ], 404);
        }

        try {
            $bookmark->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Bookmark berhasil dihapus'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menghapus bookmark'
            ], 500);
        }
    }
}