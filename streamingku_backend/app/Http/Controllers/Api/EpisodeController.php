<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Episode;
use Illuminate\Http\Request;

class EpisodeController extends Controller
{
    public function show($id)
    {
        $episode = Episode::with('film')->find($id);

        if (!$episode) {
            return response()->json([
                'status' => 'error',
                'message' => 'Episode tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $episode
        ]);
    }
}