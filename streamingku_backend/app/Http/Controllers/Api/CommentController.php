<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Comment;
use App\Models\Film;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class CommentController extends Controller
{
    /**
     * Get comments by film ID
     * GET /api/films/{filmId}/comments
     */
    public function index($filmId)
    {
        // Cek apakah film ada
        $film = Film::find($filmId);
        if (!$film) {
            return response()->json([
                'status' => 'error',
                'message' => 'Film tidak ditemukan'
            ], 404);
        }

        $comments = Comment::where('film_id', $filmId)
            ->with('user:id,name')
            ->orderBy('created_at', 'desc')
            ->get();

        // Transform data untuk Flutter
        $comments = $comments->map(function ($comment) {
            return [
                'id' => $comment->id,
                'user_id' => $comment->user_id,
                'user_name' => $comment->user->name ?? 'Unknown User',
                'content' => $comment->content,
                'created_at' => $comment->created_at,
                'is_owner' => Auth::check() && Auth::id() === $comment->user_id,
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => $comments
        ]);
    }

    /**
     * Store new comment
     * POST /api/films/{filmId}/comments
     */
    public function store(Request $request, $filmId)
    {
        // 🔥 VALIDASI
        $validator = Validator::make($request->all(), [
            'content' => 'required|string|min:2|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        // 🔥 CEK FILM
        $film = Film::find($filmId);
        if (!$film) {
            return response()->json([
                'status' => 'error',
                'message' => 'Film tidak ditemukan'
            ], 404);
        }

        // 🔥 CEK USER (Harus login)
        $user = Auth::user();
        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'User tidak terautentikasi'
            ], 401);
        }

        try {
            // 🔥 BUAT KOMENTAR
            $comment = Comment::create([
                'user_id' => $user->id,
                'film_id' => $filmId,
                'content' => $request->input('content'),
            ]);

            // 🔥 LOAD USER
            $comment->load('user:id,name');

            // 🔥 FORMAT RESPONSE
            return response()->json([
                'status' => 'success',
                'message' => 'Komentar berhasil ditambahkan',
                'data' => [
                    'id' => $comment->id,
                    'user_id' => $comment->user_id,
                    'user_name' => $comment->user->name ?? 'Unknown',
                    'content' => $comment->content,
                    'created_at' => $comment->created_at,
                    'is_owner' => true,
                ]
            ], 201);

        } catch (\Exception $e) {
            // 🔥 TAMPILKAN ERROR DETAIL
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menyimpan komentar: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete comment
     * DELETE /api/comments/{id}
     */
    public function destroy($id)
    {
        $comment = Comment::find($id);

        if (!$comment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Komentar tidak ditemukan'
            ], 404);
        }

        // 🔥 CEK KEPEMILIKAN
        if ($comment->user_id !== Auth::id()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Anda tidak memiliki izin untuk menghapus komentar ini'
            ], 403);
        }

        try {
            $comment->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Komentar berhasil dihapus'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menghapus komentar: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update comment
     * PUT /api/comments/{id}
     */
    public function update(Request $request, $id)
    {
        $comment = Comment::find($id);

        if (!$comment) {
            return response()->json([
                'status' => 'error',
                'message' => 'Komentar tidak ditemukan'
            ], 404);
        }

        if ($comment->user_id !== Auth::id()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Anda tidak memiliki izin untuk mengubah komentar ini'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'content' => 'required|string|min:2|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $comment->update([
                'content' => $request->input('content'),
            ]);

            $comment->load('user:id,name');

            return response()->json([
                'status' => 'success',
                'message' => 'Komentar berhasil diupdate',
                'data' => $comment
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Gagal mengupdate komentar: ' . $e->getMessage()
            ], 500);
        }
    }
}