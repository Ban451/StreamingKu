<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('films', function (Blueprint $table) {
            $table->id();
            $table->string('title', 200);
            $table->string('slug', 200)->unique();
            $table->text('description')->nullable();
            $table->string('poster_url')->nullable();
            $table->string('banner_url')->nullable();          // untuk banner di home
            $table->string('trailer_url')->nullable();
            $table->year('release_year')->nullable();
            $table->string('director', 100)->nullable();
            $table->string('duration', 20)->nullable();         // total durasi film (opsional)
            $table->string('rating', 10)->nullable();
            $table->integer('views_count')->default(0);
            $table->boolean('is_featured')->default(false);    // untuk banner utama
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('films');
    }
};