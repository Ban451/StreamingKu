<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('histories', function (Blueprint $table) {
            // 🔥 CEK APAKAH KOLOM duration SUDAH ADA
            if (!Schema::hasColumn('histories', 'duration')) {
                $table->integer('duration')->default(0)->after('progress');
            }
        });
    }

    public function down(): void
    {
        Schema::table('histories', function (Blueprint $table) {
            if (Schema::hasColumn('histories', 'duration')) {
                $table->dropColumn('duration');
            }
        });
    }
};