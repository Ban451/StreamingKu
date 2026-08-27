<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class History extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'film_id',
        'episode_id',
        'progress',
        'duration',
        'last_watched_at',
    ];

    protected $casts = [
        'progress' => 'integer',
        'duration' => 'integer',
        'last_watched_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // Relasi ke User
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // Relasi ke Film
    public function film()
    {
        return $this->belongsTo(Film::class);
    }

    // Relasi ke Episode
    public function episode()
    {
        return $this->belongsTo(Episode::class);
    }

    // Accessor: Progress dalam persen
    public function getProgressPercentAttribute()
    {
        if ($this->duration == 0) return 0;
        return round(($this->progress / $this->duration) * 100);
    }

    // Accessor: Progress dalam format waktu
    public function getProgressTimeAttribute()
    {
        $minutes = floor($this->progress / 60);
        $seconds = $this->progress % 60;
        return sprintf("%02d:%02d", $minutes, $seconds);
    }

    // Accessor: Duration dalam format waktu
    public function getDurationTimeAttribute()
    {
        $hours = floor($this->duration / 3600);
        $minutes = floor(($this->duration % 3600) / 60);
        $seconds = $this->duration % 60;
        
        if ($hours > 0) {
            return sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
        }
        return sprintf("%02d:%02d", $minutes, $seconds);
    }
}