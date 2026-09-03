<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\History;
use App\Models\Film;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class HistoryController extends Controller
{
    /**
     * Get all histories for authenticated user
     * GET /api/histories
     */
    public function index(Request $request)
    {
        $histories = History::where('user_id', $request->user()->id)
            ->with('film')
            ->orderBy('last_watched_at', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $histories
        ]);
    }

    /**
     * Store or update history
     * POST /api/histories
     */
    public function store(Request $request)
    {
        // 🔥 LOG REQUEST
        Log::info('📥 Store History Request:', $request->all());

        $validator = Validator::make($request->all(), [
            'film_id' => 'required|exists:films,id',
            'episode_id' => 'nullable|exists:episodes,id',
            'progress' => 'nullable|integer|min:0',
            'duration' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            Log::warning('⚠️ Validasi gagal:', $validator->errors()->toArray());
            return response()->json([
                'status' => 'error',
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = Auth::user();
        
        if (!$user) {
            Log::error('❌ User tidak terautentikasi');
            return response()->json([
                'status' => 'error',
                'message' => 'User tidak terautentikasi'
            ], 401);
        }

        try {
            // 🔥 CEK APAKAH FILM ADA
            $film = Film::find($request->film_id);
            if (!$film) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Film tidak ditemukan'
                ], 404);
            }

            // 🔥 UPDATE ATAU CREATE HISTORY
            $history = History::updateOrCreate(
                [
                    'user_id' => $user->id,
                    'film_id' => $request->film_id,
                ],
                [
                    'episode_id' => $request->episode_id,
                    'progress' => $request->progress ?? 0,
                    'duration' => $request->duration ?? 0,
                    'last_watched_at' => now(),
                ]
            );

            Log::info('✅ History saved:', [
                'id' => $history->id,
                'user_id' => $history->user_id,
                'film_id' => $history->film_id,
                'progress' => $history->progress,
                'duration' => $history->duration,
            ]);

            $history->load('film');

            return response()->json([
                'status' => 'success',
                'message' => 'History berhasil disimpan',
                'data' => $history
            ], 201);

        } catch (\Exception $e) {
            Log::error('❌ Error saving history:', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Gagal menyimpan history: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update progress history
     * PUT /api/histories/{id}
     */
    public function update(Request $request, $id)
    {
        Log::info('📥 Update Progress Request:', [
            'id' => $id,
            'data' => $request->all()
        ]);

        $validator = Validator::make($request->all(), [
            'progress' => 'required|integer|min:0',
            'duration' => 'nullable|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        $history = History::where('user_id', Auth::id())
            ->where('id', $id)
            ->first();

        if (!$history) {
            return response()->json([
                'status' => 'error',
                'message' => 'History tidak ditemukan'
            ], 404);
        }

        try {
            $history->update([
                'progress' => $request->progress,
                'duration' => $request->duration ?? $history->duration,
                'last_watched_at' => now(),
            ]);

            Log::info('✅ Progress updated:', [
                'id' => $history->id,
                'progress' => $history->progress,
                'duration' => $history->duration,
            ]);

            $history->load('film');

            return response()->json([
                'status' => 'success',
                'message' => 'Progress berhasil diupdate',
                'data' => $history
            ]);

        } catch (\Exception $e) {
            Log::error('❌ Error updating progress:', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Gagal mengupdate progress: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete history
     * DELETE /api/histories/{id}
     */
    public function destroy($id)
    {
        $history = History::where('user_id', Auth::id())
            ->where('id', $id)
            ->first();

        if (!$history) {
            return response()->json([
                'status' => 'error',
                'message' => 'History tidak ditemukan'
            ], 404);
        }

        $history->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'History berhasil dihapus'
        ]);
    }
}