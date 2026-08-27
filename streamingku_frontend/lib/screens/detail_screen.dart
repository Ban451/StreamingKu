import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/anime.dart';
import '../services/api_service.dart';
import 'streaming_screen.dart';

class DetailScreen extends StatefulWidget {
  final String animeId;

  const DetailScreen({super.key, required this.animeId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  AnimeDetail? _detail;
  bool _loading = true;
  String? _error;
  
  // 🔥 BOOKMARK STATE
  bool _isBookmarked = false;
  bool _isBookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await ApiService.instance.getAnimeDetail(widget.animeId);
      
      print('📺 ====== DETAIL FILM ======');
      print('📺 Title: ${detail.title}');
      print('📺 ID: ${detail.id}');
      print('📺 Episodes: ${detail.episodes.length}');
      for (var episode in detail.episodes) {
        print('📺 Episode ${episode.episodeNumber}: ${episode.title}');
        print('📺   Video URL: ${episode.videoUrl}');
      }
      print('📺 ==========================');
      
      setState(() {
        _detail = detail;
      });

      // 🔥 CEK STATUS BOOKMARK SETELAH LOAD DETAIL
      await _checkBookmarkStatus();

    } catch (e) {
      print('❌ Error load detail: $e');
      setState(() => _error = 'Gagal memuat detail anime: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🔥 CEK STATUS BOOKMARK
  Future<void> _checkBookmarkStatus() async {
    if (_detail == null) return;
    
    try {
      final isBookmarked = await ApiService.instance.checkBookmark(_detail!.id);
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e) {
      print('⚠️ Gagal cek bookmark: $e');
    }
  }

  /// 🔥 TOGGLE BOOKMARK
  Future<void> _toggleBookmark() async {
    if (_detail == null || _isBookmarkLoading) return;

    setState(() => _isBookmarkLoading = true);

    try {
      if (_isBookmarked) {
        // Hapus bookmark
        await ApiService.instance.removeBookmark(_detail!.id);
        setState(() => _isBookmarked = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark berhasil dihapus'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Tambah bookmark
        await ApiService.instance.addBookmark(_detail!.id);
        setState(() => _isBookmarked = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark berhasil ditambahkan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBookmarkLoading = false);
    }
  }

  /// Helper untuk mendapatkan URL video lengkap dengan HTTPS
  String _getFullVideoUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) {
      return '';
    }
    
    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      if (videoUrl.startsWith('http://')) {
        videoUrl = videoUrl.replaceFirst('http://', 'https://');
        print('🔄 Convert HTTP ke HTTPS: $videoUrl');
      }
      return videoUrl;
    }
    
    String cleanUrl = videoUrl.startsWith('/') ? videoUrl.substring(1) : videoUrl;
    final baseUrl = ApiService.baseUrl;
    
    if (cleanUrl.startsWith('storage/') || cleanUrl.startsWith('videos/')) {
      return '$baseUrl/$cleanUrl';
    }
    
    return '$baseUrl/storage/videos/$cleanUrl';
  }

  void _openEpisode(AnimeEpisode ep, AnimeDetail detail) {
    String? videoUrl = _getFullVideoUrl(ep.videoUrl);
    
    print('🎬 ====== PLAY EPISODE ======');
    print('🎬 Film ID: ${detail.id}');
    print('🎬 Anime: ${detail.title}');
    print('🎬 Episode: ${ep.episodeNumber} - ${ep.title}');
    print('🎬 Raw URL: ${ep.videoUrl}');
    print('🎬 Final URL: $videoUrl');
    print('🎬 ==========================');
    
    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video tidak tersedia untuk episode ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StreamingScreen(
          filmId: detail.id,
          animeTitle: detail.title,
          episodeTitle: 'Episode ${ep.episodeNumber} - ${ep.title}',
          videoUrl: videoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
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
                      TextButton(
                        onPressed: _load,
                        child: const Text(
                          'Coba lagi',
                          style: TextStyle(color: AppColors.accentCyan),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildContent(_detail!),
    );
  }

  Widget _buildContent(AnimeDetail detail) {
    final hasEpisodes = detail.episodes.isNotEmpty;
    final firstEpisode = hasEpisodes ? detail.episodes.first : null;
    
    return CustomScrollView(
      slivers: [
        // Banner / Poster
        SliverAppBar(
          backgroundColor: AppColors.background,
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: detail.imageUrl != null && detail.imageUrl!.isNotEmpty
                ? Image.network(
                    detail.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppColors.placeholder,
                          size: 48,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: AppColors.placeholder,
                        size: 48,
                      ),
                    ),
                  ),
          ),
          actions: [
            // 🔥 BOOKMARK BUTTON DI APP BAR
            IconButton(
              icon: _isBookmarkLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentCyan,
                      ),
                    )
                  : Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: _isBookmarked ? AppColors.accentCyan : Colors.white,
                      size: 28,
                    ),
              onPressed: _toggleBookmark,
              tooltip: _isBookmarked ? 'Hapus Bookmark' : 'Tambah Bookmark',
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Judul
              Text(
                detail.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Info tambahan (Release Year, Rating, Duration)
              if (detail.releaseYear != null || detail.rating != null || detail.duration != null)
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (detail.releaseYear != null && detail.releaseYear!.isNotEmpty)
                      _buildInfoChip(Icons.calendar_today, detail.releaseYear!),
                    if (detail.rating != null && detail.rating!.isNotEmpty)
                      _buildInfoChip(Icons.star, detail.rating!),
                    if (detail.duration != null && detail.duration!.isNotEmpty)
                      _buildInfoChip(Icons.access_time, detail.duration!),
                  ],
                ),
              const SizedBox(height: 12),

              // Genre
              if (detail.genres.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: detail.genres
                      .map((g) => Chip(
                            label: Text(
                              g,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            backgroundColor: AppColors.surfaceLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: hasEpisodes && firstEpisode != null
                          ? () => _openEpisode(firstEpisode, detail)
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasEpisodes ? 'Tonton' : 'No Episode',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: BorderSide(
                          color: _isBookmarked 
                              ? AppColors.accentCyan 
                              : AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _toggleBookmark,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isBookmarked 
                                ? Icons.bookmark 
                                : Icons.bookmark_border,
                            color: _isBookmarked 
                                ? AppColors.accentCyan 
                                : AppColors.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isBookmarked ? 'Saved' : 'Save',
                            style: TextStyle(
                              color: _isBookmarked 
                                  ? AppColors.accentCyan 
                                  : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sinopsis
              const Text(
                'Sinopsis',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail.synopsis ?? 'Sinopsis belum tersedia.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // Daftar Episode
              const Text(
                'Daftar Episode',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (detail.episodes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Belum ada episode tersedia',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...detail.episodes.map((ep) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Episode ${ep.episodeNumber}',
                                style: const TextStyle(
                                  color: AppColors.accentCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ep.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _openEpisode(ep, detail),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accentCyan.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: AppColors.accentCyan,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}