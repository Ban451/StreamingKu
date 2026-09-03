<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('histories', function (Blueprint $table) {
            // 🔥 Cek dan hapus semua UNIQUE constraint
            $this->dropUniqueIfExists($table, 'histories_user_id_film_id_unique');
            $this->dropUniqueIfExists($table, 'histories_user_id_episode_id_unique');
        });
    }

    public function down(): void
    {
        Schema::table('histories', function (Blueprint $table) {
            $table->unique(['user_id', 'film_id']);
            $table->unique(['user_id', 'episode_id']);
        });
    }

    private function dropUniqueIfExists(Blueprint $table, string $indexName): void
    {
        // 🔥 Cek apakah index ada sebelum dihapus
        $conn = Schema::getConnection();
        $tableName = $table->getTable();
        
        $indexes = $conn->getDoctrineSchemaManager()->listTableIndexes($tableName);
        if (isset($indexes[$indexName])) {
            $table->dropUnique($indexName);
        }
    }
};