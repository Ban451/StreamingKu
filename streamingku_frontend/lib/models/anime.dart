import '../services/api_service.dart';

// ================================================================
// 🔥 HELPER FUNCTIONS UNTUK URL
// ================================================================

/// 🔥 Mendapatkan base URL untuk storage (tanpa /api)
String get _storageBaseUrl {
  final baseUrl = ApiService.baseUrl;
  if (baseUrl.endsWith('/api')) {
    return baseUrl.substring(0, baseUrl.length - 4);
  }
  if (baseUrl.endsWith('/api/')) {
    return baseUrl.substring(0, baseUrl.length - 5);
  }
  return baseUrl;
}

/// 🔥 Helper untuk mendapatkan URL gambar lengkap
String? _getFullImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return null;
  
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }
  
  String cleanUrl = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
  String fileName = cleanUrl.contains('/') ? cleanUrl.split('/').last : cleanUrl;
  
  final fullUrl = '$_storageBaseUrl/storage/images/$fileName';
  return fullUrl;
}

/// 🔥 Helper untuk mendapatkan URL video lengkap
String? _getFullVideoUrl(String? videoUrl) {
  if (videoUrl == null || videoUrl.isEmpty) return null;
  
  if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
    if (videoUrl.startsWith('http://')) {
      videoUrl = videoUrl.replaceFirst('http://', 'https://');
    }
    return videoUrl;
  }
  
  String cleanUrl = videoUrl.startsWith('/') ? videoUrl.substring(1) : videoUrl;
  String fileName = cleanUrl.contains('/') ? cleanUrl.split('/').last : cleanUrl;
  
  final fullUrl = '$_storageBaseUrl/storage/videos/$fileName';
  return fullUrl;
}

// ================================================================
// MODEL
// ================================================================

/// Model utama untuk daftar/kartu anime (home, search, library, history).
class Anime {
  final String id;
  final String title;
  final String? imageUrl;
  final String? lastEpisode;
  final String? watchedAt;

  Anime({
    required this.id,
    required this.title,
    this.imageUrl,
    this.lastEpisode,
    this.watchedAt,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    String? posterUrl = json['poster_url'] ?? json['image_url'] ?? json['cover'];
    posterUrl = _getFullImageUrl(posterUrl);
    
    return Anime(
      id: json['id'].toString(),
      title: json['title'] ?? 'Judul Anime',
      imageUrl: posterUrl,
      lastEpisode: json['last_episode'] ?? json['episode_terakhir'],
      watchedAt: json['watched_at'] ?? json['grup_tanggal'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image_url': imageUrl,
        'last_episode': lastEpisode,
        'watched_at': watchedAt,
      };
}

/// Model detail anime (halaman detail) - LENGKAP dengan semua field
class AnimeDetail {
  final int id;
  final String title;
  final String? synopsis;
  final String? imageUrl;
  final String? posterUrl;
  final String? bannerUrl;
  final String? releaseYear;
  final String? rating;
  final String? duration;
  final List<String> genres;
  final List<AnimeEpisode> episodes;

  AnimeDetail({
    required this.id,
    required this.title,
    this.synopsis,
    this.imageUrl,
    this.posterUrl,
    this.bannerUrl,
    this.releaseYear,
    this.rating,
    this.duration,
    this.genres = const [],
    this.episodes = const [],
  });

  factory AnimeDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    String? posterUrl = data['poster_url'];
    String? bannerUrl = data['banner_url'];
    String? imageUrl = data['image_url'] ?? posterUrl ?? bannerUrl;
    
    imageUrl = _getFullImageUrl(imageUrl);
    posterUrl = _getFullImageUrl(posterUrl);
    bannerUrl = _getFullImageUrl(bannerUrl);
    
    return AnimeDetail(
      id: data['id'] ?? 0,
      title: data['title'] ?? 'Unknown',
      synopsis: data['synopsis'] ?? data['description'],
      imageUrl: imageUrl,
      posterUrl: posterUrl,
      bannerUrl: bannerUrl,
      releaseYear: data['release_year']?.toString(),
      rating: data['rating'],
      duration: data['duration'],
      genres: data['genres'] != null 
          ? List<String>.from(data['genres']) 
          : [],
      episodes: data['episodes'] != null
          ? (data['episodes'] as List)
              .map((e) => AnimeEpisode.fromJson(e))
              .toList()
          : [],
    );
  }
}

/// Model episode anime
class AnimeEpisode {
  final int id;
  final int episodeNumber;
  final String title;
  final String? videoUrl;
  final String? duration;

  AnimeEpisode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    this.videoUrl,
    this.duration,
  });

  factory AnimeEpisode.fromJson(Map<String, dynamic> json) {
    String? videoUrl = json['video_url'];
    videoUrl = _getFullVideoUrl(videoUrl);
    
    return AnimeEpisode(
      id: json['id'] ?? 0,
      episodeNumber: json['episode_number'] ?? json['episode'] ?? 0,
      title: json['title'] ?? 'Episode ${json['episode_number'] ?? json['id']}',
      videoUrl: videoUrl,
      duration: json['duration'],
    );
  }
}

/// Model komentar pada halaman streaming
class Comment {
  final String id;
  final String userName;
  final String text;
  final bool isOwner;
  final DateTime? createdAt;

  Comment({
    required this.id,
    required this.userName,
    required this.text,
    this.isOwner = false,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'].toString(),
      userName: user?['name'] ?? json['user_name'] ?? 'User',
      text: json['content'] ?? json['text'] ?? '',
      isOwner: json['is_owner'] == true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }
}

/// Model user (login/register/profile)
class AppUser {
  final int id;
  final String fullName;
  final String username;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['avatar'] ?? json['avatar_url'];
    avatarUrl = _getFullImageUrl(avatarUrl);
    
    return AppUser(
      id: json['id'] ?? 0,
      fullName: json['name'] ?? json['full_name'] ?? '',
      username: json['email'] ?? json['username'] ?? '',
      avatarUrl: avatarUrl,
    );
  }
}

/// Model untuk bookmark / library
class Bookmark {
  final int id;
  final int filmId;
  final Anime? film;
  final DateTime? createdAt;

  Bookmark({
    required this.id,
    required this.filmId,
    this.film,
    this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? 0,
      filmId: json['film_id'] ?? 0,
      film: json['film'] != null ? Anime.fromJson(json['film']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }
}

/// 🔥 Model untuk history - DENGAN PROGRESS
class History {
  final int id;
  final int filmId;
  final Anime? film;
  final int? episodeId;
  final int progress;
  final int duration;
  final DateTime? watchedAt;

  History({
    required this.id,
    required this.filmId,
    this.film,
    this.episodeId,
    this.progress = 0,
    this.duration = 0,
    this.watchedAt,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] ?? 0,
      filmId: json['film_id'] ?? 0,
      film: json['film'] != null ? Anime.fromJson(json['film']) : null,
      episodeId: json['episode_id'],
      progress: json['progress'] ?? 0,
      duration: json['duration'] ?? 0,
      watchedAt: json['watched_at'] != null 
          ? DateTime.tryParse(json['watched_at']) 
          : null,
    );
  }
}