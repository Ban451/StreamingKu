<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('episodes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('film_id')->constrained()->onDelete('cascade');
            $table->unsignedSmallInteger('episode_number')->default(1);
            $table->string('title', 200)->nullable();           // contoh: "Full Movie" / "Episode 1"
            $table->string('video_url');                        // path di storage Laravel
            $table->string('duration', 20)->nullable();         // Format: 01:30:00
            $table->integer('views_count')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            // Satu film hanya boleh punya 1 episode dengan nomor yang sama
            $table->unique(['film_id', 'episode_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('episodes');
    }
};