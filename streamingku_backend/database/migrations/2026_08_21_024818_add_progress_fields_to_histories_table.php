<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 🔥 TAMBAHKAN KOLOM KE TABEL histories
        Schema::table('histories', function (Blueprint $table) {
            // Cek apakah kolom sudah ada sebelum menambahkan
            if (!Schema::hasColumn('histories', 'progress')) {
                $table->integer('progress')->default(0)->after('episode_id');
            }
            if (!Schema::hasColumn('histories', 'duration')) {
                $table->integer('duration')->default(0)->after('progress');
            }
            if (!Schema::hasColumn('histories', 'last_watched_at')) {
                $table->timestamp('last_watched_at')->nullable()->after('duration');
            }
        });
    }

    public function down(): void
    {
        Schema::table('histories', function (Blueprint $table) {
            $table->dropColumn(['progress', 'duration', 'last_watched_at']);
        });
    }
};