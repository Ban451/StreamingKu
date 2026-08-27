<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // User dummy untuk testing login
        User::factory()->create([
            'name'     => 'Test User',
            'email'    => 'test@example.com',
            'password' => bcrypt('password123'),
        ]);

        // Jalankan FilmSeeder
        $this->call([
            FilmSeeder::class,
        ]);
    }
}