<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class FilmSeeder extends Seeder
{
    public function run(): void
    {
        // 🔥 BUAT FOLDER JIKA BELUM ADA
        if (!Storage::disk('public')->exists('images')) {
            Storage::disk('public')->makeDirectory('images');
            $this->command->info('📁 Folder images created');
        }
        if (!Storage::disk('public')->exists('videos')) {
            Storage::disk('public')->makeDirectory('videos');
            $this->command->info('📁 Folder videos created');
        }

        $films = [
            [
                'title' => 'Kimi no Nawa',
                'description' => 'Mitsuha, gadis SMA di desa pegunungan, dan Taki, pemuda di Tokyo, secara misterius bertukar tubuh. Mereka mencoba mencari tahu penyebabnya sambil membangun hubungan yang mendalam melintasi waktu dan ruang.',
                'release_year' => 2016,
                'director' => 'Makoto Shinkai',
                'duration' => '01:46:00',
                'rating' => 'PG-13',
                'is_featured' => true,
                'poster_url' => 'images/kimi-no-nawa.jpg',
                'banner_url' => null,
                'video_file' => 'kimi-no-nawa.mp4',
            ],
            [
                'title' => 'Tenki no Ko',
                'description' => 'Hodaka lari dari rumah ke Tokyo dan bertemu Hina, gadis yang memiliki kemampuan untuk menghentikan hujan. Bersama-sama mereka mencoba bertahan hidup di kota sambil menghadapi konsekuensi dari kekuatan Hina.',
                'release_year' => 2019,
                'director' => 'Makoto Shinkai',
                'duration' => '01:52:00',
                'rating' => 'PG-13',
                'is_featured' => true,
                'poster_url' => 'images/tenki-no-ko.jpg',
                'banner_url' => null,
                'video_file' => 'tenki-no-ko.mp4',
            ],
            [
                'title' => 'Suzume no Tojimari',
                'description' => 'Suzume, gadis SMA, bertemu pemuda misterius yang sedang mencari pintu-pintu yang menyebabkan bencana. Bersama-sama mereka berkeliling Jepang untuk menutup pintu-pintu tersebut.',
                'release_year' => 2022,
                'director' => 'Makoto Shinkai',
                'duration' => '02:02:00',
                'rating' => 'PG-13',
                'is_featured' => true,
                'poster_url' => 'images/suzume.jpg',
                'banner_url' => null,
                'video_file' => 'suzume.mp4',
            ],
            [
                'title' => 'Koe no Katachi',
                'description' => 'Shoya Ishida menyesali masa lalunya yang telah membully Shoko Nishimiya, gadis tuna rungu. Bertahun-tahun kemudian ia mencoba menebus kesalahannya dan belajar arti dari komunikasi serta penebusan.',
                'release_year' => 2016,
                'director' => 'Naoko Yamada',
                'duration' => '02:10:00',
                'rating' => 'PG-13',
                'is_featured' => false,
                'poster_url' => 'images/koe-no-katachi.jpg',
                'banner_url' => null,
                'video_file' => 'koe-no-katachi.mp4',
            ],
            [
                'title' => 'Doraemon: Stand by Me',
                'description' => 'Nobita dan Doraemon mengalami petualangan emosional saat Nobita di masa depan mencoba mengubah takdirnya. Film ini mengangkat tema persahabatan dan keluarga dengan sangat menyentuh.',
                'release_year' => 2014,
                'director' => 'Ryūichi Yagi, Takashi Yamazaki',
                'duration' => '01:35:00',
                'rating' => 'G',
                'is_featured' => false,
                'poster_url' => 'images/stand-by-me-doraemon.jpg',
                'banner_url' => null,
                'video_file' => 'doraemon-stand-by-me.mp4',
            ],
            [
                'title' => 'One Piece Film: Red',
                'description' => 'Luffy dan kru Topi Jerami menghadiri konser Uta, diva paling dicintai di dunia yang ternyata memiliki hubungan misterius dengan Shanks. Konser tersebut berubah menjadi ancaman besar bagi dunia.',
                'release_year' => 2022,
                'director' => 'Gorō Taniguchi',
                'duration' => '01:55:00',
                'rating' => 'PG-13',
                'is_featured' => true,
                'poster_url' => 'images/one-piece-red.jpg',
                'banner_url' => null,
                'video_file' => 'one-piece-red.mp4',
            ],
        ];

        foreach ($films as $film) {
            // Cek apakah film sudah ada
            $existing = DB::table('films')->where('slug', Str::slug($film['title']))->first();
            
            if ($existing) {
                $this->command->warn("⚠️ Film '{$film['title']}' sudah ada, dilewati...");
                continue;
            }

            // Insert ke tabel films
            $filmId = DB::table('films')->insertGetId([
                'title'         => $film['title'],
                'slug'          => Str::slug($film['title']),
                'description'   => $film['description'],
                'poster_url'    => $film['poster_url'],
                'banner_url'    => $film['banner_url'],
                'trailer_url'   => null,
                'release_year'  => $film['release_year'],
                'director'      => $film['director'],
                'duration'      => $film['duration'],
                'rating'        => $film['rating'],
                'views_count'   => 0,
                'is_featured'   => $film['is_featured'],
                'is_active'     => true,
                'created_at'    => now(),
                'updated_at'    => now(),
            ]);

            // Insert episode
            DB::table('episodes')->insert([
                'film_id'         => $filmId,
                'episode_number'  => 1,
                'title'           => 'Full Movie',
                'video_url'       => '/storage/videos/' . $film['video_file'],
                'duration'        => $film['duration'],
                'views_count'     => 0,
                'is_active'       => true,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);

            $this->command->info("✅ Film '{$film['title']}' berhasil ditambahkan!");
        }

        $this->command->info('🎉 Semua film berhasil di-seed!');
    }
}