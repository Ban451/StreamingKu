<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Film extends Model
{
    protected $fillable = [
        'title',
        'slug',
        'description',
        'poster_url',
        'banner_url',
        'trailer_url',
        'release_year',
        'director',
        'duration',
        'rating',
        'views_count',
        'is_featured',
        'is_active'
    ];

    protected $casts = [
        'release_year' => 'integer',
        'views_count' => 'integer',
        'is_featured' => 'boolean',
        'is_active' => 'boolean',
    ];

    // 🔥 RELASI KE EPISODE
    public function episodes()
    {
        return $this->hasMany(Episode::class);
    }

    // 🔥 RELASI KE COMMENT
    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    // 🔥 RELASI KE HISTORY
    public function histories()
    {
        return $this->hasMany(History::class);
    }

    // 🔥 RELASI KE BOOKMARK
    public function bookmarks()
    {
        return $this->hasMany(Bookmark::class);
    }
}