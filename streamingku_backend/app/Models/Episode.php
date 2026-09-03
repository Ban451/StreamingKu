<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Episode extends Model
{
    protected $fillable = [
        'film_id',
        'episode_number',
        'title',
        'video_url',
        'duration',
        'views_count',
        'is_active'
    ];

    public function film()
    {
        return $this->belongsTo(Film::class);
    }

    // 🔥 PERBAIKI ACCESSOR VIDEO URL
    public function getVideoUrlAttribute($value)
    {
        if (!$value) {
            return null;
        }

        // Jika sudah URL lengkap (http/https)
        if (filter_var($value, FILTER_VALIDATE_URL)) {
            return $value;
        }

        // 🔥 UNTUK LOCALHOST - gunakan asset() dengan benar
        // Jika path di storage
        if (Storage::disk('public')->exists($value)) {
            // 🔥 PAKAI asset() TANPA 'storage/' KARENA SUDAH ADA DI URL
            return asset($value);
        }

        // Jika path dimulai dengan /storage/
        if (str_starts_with($value, '/storage/')) {
            return asset($value);
        }

        // Fallback
        return asset('storage/' . ltrim($value, '/'));
    }
}