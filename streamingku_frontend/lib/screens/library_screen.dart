import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/anime.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Anime> _bookmarks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🔥 Refresh data ketika kembali ke screen ini
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    // 🔥 CEK TOKEN DULU
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ Token tidak ada, redirect ke login');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 🔥 CEK TOKEN VALID
      try {
        await ApiService.instance.getProfile();
        debugPrint('✅ Token valid');
      } catch (e) {
        debugPrint('❌ Token invalid: $e');
        await prefs.remove('auth_token');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
        return;
      }

      final bookmarks = await ApiService.instance.getLibrary();
      debugPrint('📚 Library loaded: ${bookmarks.length} items');
      
      setState(() {
        _bookmarks = bookmarks;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('❌ Error load library: $e');
      setState(() {
        _error = 'Gagal memuat library: ${e.toString().replaceAll('Exception: ', '')}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Library',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          // 🔥 TOMBOL REFRESH DI APP BAR
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadLibrary,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLibrary,
        color: AppColors.accentCyan,
        backgroundColor: AppColors.surface,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentCyan,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.registerRed,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 🔥 TOMBOL RETRY
                        ElevatedButton(
                          onPressed: _loadLibrary,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentCyan,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  )
                : _bookmarks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              color: AppColors.textSecondary.withOpacity(0.5),
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada anime tersimpan',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan bookmark dari halaman detail anime',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 🔥 TOMBOL JELAJAHI ANIME
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentCyan,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Jelajahi Anime',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 🔥 TOMBOL REFRESH DI KOSONG
                            TextButton(
                              onPressed: _loadLibrary,
                              child: const Text(
                                'Refresh',
                                style: TextStyle(
                                  color: AppColors.accentCyan,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _bookmarks.length,
                        itemBuilder: (context, index) {
                          final anime = _bookmarks[index];
                          return _buildBookmarkCard(anime);
                        },
                      ),
      ),
    );
  }

  Widget _buildBookmarkCard(Anime anime) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(animeId: anime.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: anime.imageUrl != null && anime.imageUrl!.isNotEmpty
                  ? Image.network(
                      anime.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: AppColors.placeholder,
                            size: 30,
                          ),
                        ),
                      ),
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.surfaceLight,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentCyan,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Icon(
                          Icons.movie,
                          color: AppColors.placeholder,
                          size: 30,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            anime.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // 🔥 BOOKMARK INDICATOR
          Row(
            children: [
              const Icon(
                Icons.bookmark,
                color: AppColors.accentCyan,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Tersimpan',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}