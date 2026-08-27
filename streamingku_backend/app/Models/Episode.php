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

    protected $casts = [
        'episode_number' => 'integer',
        'views_count' => 'integer',
        'is_active' => 'boolean',
    ];

    // Relasi ke Film
    public function film()
    {
        return $this->belongsTo(Film::class);
    }

    // Accessor untuk mendapatkan URL video lengkap
    public function getVideoUrlAttribute($value)
    {
        if (!$value) {
            return null;
        }

        // Jika sudah URL lengkap (http/https)
        if (filter_var($value, FILTER_VALIDATE_URL)) {
            return $value;
        }

        // Jika path di storage
        if (Storage::disk('public')->exists($value)) {
            return Storage::url($value);
        }

        // Jika path di public
        if (file_exists(public_path($value))) {
            return asset($value);
        }

        // Fallback: coba dengan storage
        return asset('storage/' . $value);
    }

    // Mutator untuk menyimpan video_url
    public function setVideoUrlAttribute($value)
    {
        $this->attributes['video_url'] = $value;
    }
}