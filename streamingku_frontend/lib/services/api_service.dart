import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// --- IMPORT MODEL ---
import '../models/anime.dart' as AnimeModel;
import '../models/user.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ================== GANTI URL NGROK KAMU DI SINI ==================
  static const String baseUrl = "http://192.168.110.232:8000/api";
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
    debugPrint('📝 Mencoba login: $email');

    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    debugPrint('📊 Login status: ${res.statusCode}');
    debugPrint('📊 Login response: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();

      final token =
          data['token'] ??
          data['access_token'] ??
          data['data']['token'] ??
          data['data']['access_token'];

      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        debugPrint('✅ Token tersimpan');
      } else {
        debugPrint('⚠️ Token tidak ditemukan di response');
        debugPrint('📊 Response keys: ${data.keys}');
      }

      final userData =
          data['data']['user'] ?? data['user'] ?? data['data'] ?? data;

      if (userData is Map<String, dynamic>) {
        return AppUser.fromJson(userData);
      } else {
        throw Exception('User data tidak ditemukan di response');
      }
    }

    try {
      final error = jsonDecode(res.body);
      final message = error['message'] ?? 'Login gagal';
      throw Exception(message);
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
    debugPrint('📝 Mencoba register: $email');

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

    debugPrint('📊 Register status: ${res.statusCode}');
    debugPrint('📊 Register response BODY: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();

      final token =
          data['token'] ??
          data['access_token'] ??
          data['data']['token'] ??
          data['data']['access_token'];

      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        debugPrint('✅ Token tersimpan');
      } else {
        debugPrint('⚠️ Token tidak ditemukan di response');
        debugPrint('📊 Response keys: ${data.keys}');
      }

      final userData =
          data['data']['user'] ?? data['user'] ?? data['data'] ?? data;

      if (userData is Map<String, dynamic>) {
        return AppUser.fromJson(userData);
      } else {
        throw Exception('User data tidak ditemukan di response');
      }
    }

    // 🔥 TAMPILKAN ERROR DETAIL
    try {
      final error = jsonDecode(res.body);
      debugPrint('📊 Error detail: $error');

      final message = error['message'] ?? 'Registrasi gagal';

      // Jika ada detail error per field
      if (error['errors'] != null) {
        final errors = error['errors'] as Map<String, dynamic>;
        debugPrint('📊 Field errors: $errors');

        // Ambil error pertama
        final firstError = errors.values.first.first;
        throw Exception(firstError);
      }

      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Registrasi gagal: ${res.statusCode}');
    }
  }

  Future<void> logout() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await _authHeaders(),
      );
      debugPrint('📊 Logout status: ${res.statusCode}');
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    debugPrint('🔓 Logout berhasil');
  }

  // ================================================================
  // PROFILE / ME
  // ================================================================

  Future<AppUser> getProfile() async {
    debugPrint('📥 Mengambil profil user...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: await _authHeaders(),
    );

    debugPrint('📊 Profile status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final userData = data['data'] ?? data['user'] ?? data;

      if (userData is Map<String, dynamic>) {
        return AppUser.fromJson(userData);
      } else {
        throw Exception('User data tidak ditemukan');
      }
    } else if (res.statusCode == 401) {
      debugPrint('⚠️ Token expired');
      await prefs.remove('auth_token');
      throw Exception('Sesi telah berakhir');
    }

    throw Exception('Gagal memuat profil (${res.statusCode})');
  }

  // ================================================================
  // FILM / ANIME
  // ================================================================

  Future<List<AnimeModel.Anime>> getAnimeList() async {
    debugPrint('📥 Mengambil daftar anime...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ Token tidak ada');
      return [];
    }

    final res = await http.get(
      Uri.parse('$baseUrl/films'),
      headers: await _authHeaders(),
    );

    debugPrint('📊 Anime list status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];

      if (data.isEmpty) {
        debugPrint('⚠️ Data anime kosong');
        return [];
      }

      debugPrint('✅ Mendapat ${data.length} anime');
      return data.map((e) => AnimeModel.Anime.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      debugPrint('⚠️ Token expired');
      await prefs.remove('auth_token');
      throw Exception('Sesi telah berakhir');
    }

    throw Exception('Gagal memuat daftar anime (${res.statusCode})');
  }

  Future<List<AnimeModel.Anime>> getFeatured() async {
    debugPrint('📥 Mengambil featured anime...');

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
    debugPrint('📥 Mengambil detail anime: $animeId');

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
    debugPrint('🔍 Mencari anime: $query');

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
    debugPrint('📥 Mengambil history...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ Tidak ada token, history kosong');
      return [];
    }

    final res = await http.get(
      Uri.parse('$baseUrl/histories'),
      headers: await _authHeaders(),
    );

    debugPrint('📊 History status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];

      if (data.isEmpty) {
        debugPrint('ℹ️ History kosong');
        return [];
      }

      if (data.isNotEmpty && data[0].containsKey('film')) {
        return data.map((e) => AnimeModel.Anime.fromJson(e['film'])).toList();
      }

      return data.map((e) => AnimeModel.Anime.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      debugPrint('⚠️ Token expired');
      await prefs.remove('auth_token');
      return [];
    }

    throw Exception('Gagal memuat riwayat (${res.statusCode})');
  }

  Future<List<AnimeModel.History>> getHistoryWithProgress() async {
    debugPrint('📥 Mengambil history dengan progress...');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ Tidak ada token');
      return [];
    }

    final res = await http.get(
      Uri.parse('$baseUrl/histories'),
      headers: await _authHeaders(),
    );

    debugPrint('📊 History status: ${res.statusCode}');

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body);
      final List data = responseData['data'] ?? [];

      if (data.isEmpty) {
        debugPrint('ℹ️ History kosong');
        return [];
      }

      return data.map((e) => AnimeModel.History.fromJson(e)).toList();
    } else if (res.statusCode == 401) {
      debugPrint('⚠️ Token expired');
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
    debugPrint('📥 Menambah history: film $filmId');

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
    debugPrint('📥 Update history: $historyId, progress: $progress');

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
    debugPrint('📥 Mengambil library...');

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
    debugPrint('📥 Cek bookmark: film $filmId');

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
    debugPrint('📥 Menambah bookmark: film $filmId');

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
    debugPrint('📥 Menghapus bookmark: film $filmId');

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
    debugPrint('📥 Mengambil komentar untuk film: $filmId');

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
    debugPrint('📥 Posting komentar untuk film: $filmId');

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
    debugPrint('📥 Menghapus komentar: $commentId');

    final res = await http.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: await _authHeaders(),
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus komentar');
    }
  }
}
