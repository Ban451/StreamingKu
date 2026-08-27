<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name' => 'Action', 'description' => 'Film aksi dengan pertarungan dan ledakan'],
            ['name' => 'Drama', 'description' => 'Film dengan cerita emosional dan konflik'],
            ['name' => 'Comedy', 'description' => 'Film komedi yang menghibur'],
            ['name' => 'Horror', 'description' => 'Film horor yang menegangkan'],
            ['name' => 'Sci-Fi', 'description' => 'Film fiksi ilmiah dengan teknologi futuristik'],
            ['name' => 'Romance', 'description' => 'Film cinta dan percintaan'],
            ['name' => 'Thriller', 'description' => 'Film thriller yang penuh ketegangan'],
            ['name' => 'Animation', 'description' => 'Film animasi untuk semua usia'],
        ];

        foreach ($categories as $category) {
            DB::table('categories')->insert([
                'name' => $category['name'],
                'slug' => Str::slug($category['name']),
                'description' => $category['description'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}