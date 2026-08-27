<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('histories', function (Blueprint $table) {
            // 🔥 CEK APAKAH KOLOM film_id SUDAH ADA
            if (!Schema::hasColumn('histories', 'film_id')) {
                $table->unsignedBigInteger('film_id')->after('user_id');
                $table->foreign('film_id')->references('id')->on('films')->onDelete('cascade');
            }
        });
    }

    public function down(): void
    {
        Schema::table('histories', function (Blueprint $table) {
            if (Schema::hasColumn('histories', 'film_id')) {
                $table->dropForeign(['film_id']);
                $table->dropColumn('film_id');
            }
        });
    }
};