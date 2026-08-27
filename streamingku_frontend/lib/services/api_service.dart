import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORT MODEL ---
import '../models/anime.dart' as AnimeModel;
import '../models/user.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ================== GANTI URL NGROK KAMU DI SINI ==================
  static const String baseUrl = "https://reproachless-caroyln-ruttily.ngrok-free.dev/api";
  // ==================================================================

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      ..._headers,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ================================================================
  // AUTH
  // ================================================================

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    print('📝 Mencoba login: $email');
    
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    print('📊 Login status: ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();

      final token = data['token'] ?? 
                     data['access_token'] ?? 
                     data['data']['token'] ?? 
                     data['data']['access_token'];
      
      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        print('✅ Token tersimpan');
      }

      final userData = data['data']['user'] ?? 
                        data['user'] ?? 
                        data['data'] ?? 
                        data;
      
      if (userData is Map<String, dynamic>) {
        return AppUser.fromJson(userData);
      } else {
        throw Exception('User data tidak ditemukan');
      }
    }

    try {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Login gagal');
    } catch (e) {
      throw Exception('Login gagal: ${res.statusCode}');
    }
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    print('📝 Mencoba register: $email');
    
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    print('📊 Register status: ${res.statusCode}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      
      final token = data['token'] ?? 
                     data['access_token'] ?? 
                     data['data']['token'] ?? 
                     data['data']['access_token'];
      
      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        print('✅ Token tersimpan');
      }

      final userData = data['data']['user'] ?? 
                        data['user'] ?? 
                        data['data'] ?? 
                        data;
      
      if (userData is Map<String, dynamic>) {
        return AppUser.fromJson(userData);
      } else {
        throw Exception('User data tidak ditemukan');
      }
    }

    try {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Registrasi gagal');
    } catch (e) {
      throw Exception('Registrasi gagal: ${res.statusCode}');
    }
  }

  Future<void> logout() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _authHeaders(),
      );
      print('📊 Logout status: ${res.statusCode}');
    } catch (e) {
      print('⚠️ Logout error: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print('🔓 Logout berhasil');
  }

  // ================================================================
  // PROFILE / ME
  // ================================================================

  Future<AppUser> getProfile() async {
    print('📥 Mengambil profil user...');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan');
    }
    
    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: await _authHeaders(),
    );

    print('📊 Profile status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final userData = data['data'] ?? data['user'] ?? data;
      
      if (userData is Map<String, dynamic>) {
        return AppUser.fromJson(userData);
      } else {
        throw Exception('User data tidak ditemukan');
      }
    } else if (res.statusCode == 401) {
      print('⚠️ Token expired');
      await prefs.remove('auth_token');
      throw Exception('Sesi telah berakhir');
    }
    
    throw Exception('Gagal memuat profil (${res.statusCode})');
  }

  // ================================================================
  // FILM / ANIME
  // ================================================================

  Future<List<AnimeModel.Anime>> getAnimeList() async {
    print('📥 Mengambil daftar anime...');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null || token.isEmpty) {
      print('⚠️ Token tidak ada');
      return [];
    }
    
    final res = await http.get(
      Uri.parse('$baseUrl/films'),
      headers: await _authHeaders(),
    );

    print('📊 Anime list status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];
      
      if (data.isEmpty) {
        print('⚠️ Data anime kosong');
        return [];
      }
      
      print('✅ Mendapat ${data.length} anime');
      return data.map((e) => AnimeModel.Anime.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      print('⚠️ Token expired');
      await prefs.remove('auth_token');
      throw Exception('Sesi telah berakhir');
    }
    
    throw Exception('Gagal memuat daftar anime (${res.statusCode})');
  }

  Future<List<AnimeModel.Anime>> getFeatured() async {
    print('📥 Mengambil featured anime...');
    
    final res = await http.get(
      Uri.parse('$baseUrl/films/featured'),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];
      return data.map((e) => AnimeModel.Anime.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat featured');
  }

  Future<AnimeModel.AnimeDetail> getAnimeDetail(String animeId) async {
    print('📥 Mengambil detail anime: $animeId');
    
    final res = await http.get(
      Uri.parse('$baseUrl/films/$animeId'),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final data = responseData['data'] ?? responseData;
      return AnimeModel.AnimeDetail.fromJson(data);
    }
    throw Exception('Gagal memuat detail anime');
  }

  // ================================================================
  // SEARCH
  // ================================================================

  Future<List<AnimeModel.Anime>> searchAnime(String query) async {
    print('🔍 Mencari anime: $query');
    
    final res = await http.get(
      Uri.parse('$baseUrl/films/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];
      return data.map((e) => AnimeModel.Anime.fromJson(e)).toList();
    }
    throw Exception('Gagal mencari anime');
  }

  // ================================================================
  // HISTORY
  // ================================================================

  Future<List<AnimeModel.Anime>> getHistory() async {
    print('📥 Mengambil history...');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null || token.isEmpty) {
      print('⚠️ Tidak ada token, history kosong');
      return [];
    }
    
    final res = await http.get(
      Uri.parse('$baseUrl/histories'),
      headers: await _authHeaders(),
    );

    print('📊 History status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];
      
      if (data.isEmpty) {
        print('ℹ️ History kosong');
        return [];
      }
      
      if (data.isNotEmpty && data[0].containsKey('film')) {
        return data.map((e) => AnimeModel.Anime.fromJson(e['film'])).toList();
      }
      
      return data.map((e) => AnimeModel.Anime.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      print('⚠️ Token expired');
      await prefs.remove('auth_token');
      return [];
    }
    
    throw Exception('Gagal memuat riwayat (${res.statusCode})');
  }

  Future<List<AnimeModel.History>> getHistoryWithProgress() async {
    print('📥 Mengambil history dengan progress...');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null || token.isEmpty) {
      print('⚠️ Tidak ada token');
      return [];
    }
    
    final res = await http.get(
      Uri.parse('$baseUrl/histories'),
      headers: await _authHeaders(),
    );

    print('📊 History status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];
      
      if (data.isEmpty) {
        print('ℹ️ History kosong');
        return [];
      }
      
      return data.map((e) => AnimeModel.History.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      print('⚠️ Token expired');
      await prefs.remove('auth_token');
      return [];
    }
    
    throw Exception('Gagal memuat riwayat (${res.statusCode})');
  }

  Future<Map<String, dynamic>> addHistory({
    required int filmId,
    int? episodeId,
    int progress = 0,
    int duration = 0,
  }) async {
    print('📥 Menambah history: film $filmId');
    
    final res = await http.post(
      Uri.parse('$baseUrl/histories'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'film_id': filmId,
        if (episodeId != null) 'episode_id': episodeId,
        'progress': progress,
        'duration': duration,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return data['data'] ?? {};
    }
    
    throw Exception('Gagal menyimpan history');
  }

  Future<void> updateHistory({
    required int historyId,
    required int progress,
    int? duration,
  }) async {
    print('📥 Update history: $historyId, progress: $progress');
    
    final res = await http.put(
      Uri.parse('$baseUrl/histories/$historyId'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'progress': progress,
        if (duration != null) 'duration': duration,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengupdate history');
    }
  }

  // ================================================================
  // BOOKMARK
  // ================================================================

  Future<List<AnimeModel.Anime>> getLibrary() async {
    print('📥 Mengambil library...');
    
    final res = await http.get(
      Uri.parse('$baseUrl/bookmarks'),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];
      
      if (data.isEmpty) return [];
      
      List<AnimeModel.Anime> result = [];
      for (var item in data) {
        if (item.containsKey('film') && item['film'] != null) {
          result.add(AnimeModel.Anime.fromJson(item['film']));
        }
      }
      return result;
    }
    throw Exception('Gagal memuat library');
  }

  Future<bool> checkBookmark(int filmId) async {
    print('📥 Cek bookmark: film $filmId');
    
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/bookmarks/check/$filmId'),
        headers: await _authHeaders(),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data']['is_bookmarked'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> addBookmark(int filmId) async {
    print('📥 Menambah bookmark: film $filmId');
    
    final res = await http.post(
      Uri.parse('$baseUrl/bookmarks'),
      headers: await _authHeaders(),
      body: jsonEncode({'film_id': filmId}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Gagal menambah bookmark');
    }
  }

  Future<void> removeBookmark(int filmId) async {
    print('📥 Menghapus bookmark: film $filmId');
    
    final res = await http.delete(
      Uri.parse('$baseUrl/bookmarks/$filmId'),
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus bookmark');
    }
  }

  // ================================================================
  // COMMENTS
  // ================================================================

  Future<List<AnimeModel.Comment>> getComments(int filmId) async {
    print('📥 Mengambil komentar untuk film: $filmId');
    
    final res = await http.get(
      Uri.parse('$baseUrl/films/$filmId/comments'),
      headers: await _authHeaders(),
    );

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];
      return data.map((e) => AnimeModel.Comment.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat komentar');
  }

  Future<void> postComment(int filmId, String content) async {
    print('📥 Posting komentar untuk film: $filmId');
    
    final res = await http.post(
      Uri.parse('$baseUrl/films/$filmId/comments'),
      headers: await _authHeaders(),
      body: jsonEncode({'content': content}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Gagal mengirim komentar');
      } catch (e) {
        throw Exception('Gagal mengirim komentar (${res.statusCode})');
      }
    }
  }

  Future<void> deleteComment(int commentId) async {
    print('📥 Menghapus komentar: $commentId');
    
    final res = await http.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus komentar');
    }
  }
}