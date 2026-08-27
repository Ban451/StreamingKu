<?php

namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;

use App\Models\Film;
use Illuminate\Http\Request;

class FilmController extends Controller
{
    public function index()
    {
        $films = Film::where('is_active', true)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $films
        ]);
    }

    public function featured()
    {
        $films = Film::where('is_active', true)
            ->where('is_featured', true)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $films
        ]);
    }

    public function show($id)
    {
        $film = Film::with('episodes')->where('is_active', true)->find($id);

        if (!$film) {
            return response()->json([
                'status' => 'error',
                'message' => 'Film tidak ditemukan'
            ], 404);
        }

        // Pastikan episode memiliki video_url lengkap
        $film->episodes->each(function ($episode) {
            $episode->video_url = $episode->video_url;
        });

        return response()->json([
            'status' => 'success',
            'data' => $film
        ]);
    }

    public function search(Request $request)
    {
        $query = $request->get('q', '');
        
        if (empty($query)) {
            return response()->json([
                'status' => 'success',
                'data' => []
            ]);
        }

        $films = Film::where('is_active', true)
            ->where('title', 'LIKE', "%{$query}%")
            ->orWhere('description', 'LIKE', "%{$query}%")
            ->orderBy('views_count', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $films
        ]);
    }
}