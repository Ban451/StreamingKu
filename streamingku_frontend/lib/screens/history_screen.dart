import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/anime.dart';
import '../services/api_service.dart';
import 'streaming_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<History> _history = [];
  bool _loading = true;
  String? _error;

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
      final data = await ApiService.instance.getHistoryWithProgress();
      setState(() => _history = data);
      debugPrint('✅ History loaded: ${_history.length} items');
    } catch (e) {
      debugPrint('❌ Error load history: $e');
      setState(() => _error = 'Gagal memuat riwayat: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 🔥 Format waktu (detik ke MM:SS atau HH:MM:SS)
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// 🔥 Buka streaming LANGSUNG dari progress terakhir
  void _openStreaming(History history) async {
    if (history.film == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data film tidak tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final anime = history.film!;
    
    debugPrint('🎬 ====== PLAY FROM HISTORY ======');
    debugPrint('🎬 Film: ${anime.title}');
    debugPrint('🎬 Film ID: ${history.filmId}');
    debugPrint('🎬 Progress: ${history.progress} / ${history.duration}');
    debugPrint('🎬 ================================');

    // 🔥 TAMPILKAN LOADING
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.accentCyan),
      ),
    );

    try {
      // 🔥 AMBIL DETAIL FILM
      final detail = await ApiService.instance.getAnimeDetail(anime.id);
      
      if (!mounted) {
        try { Navigator.pop(context); } catch (_) {}
        return;
      }
      try { Navigator.pop(context); } catch (_) {} // Tutup loading

      // 🔥 CEK APAKAH ADA EPISODE
      if (detail.episodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada episode untuk film ini'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 🔥 CARI EPISODE
      AnimeEpisode targetEpisode;
      
      if (history.episodeId != null) {
        try {
          targetEpisode = detail.episodes.firstWhere(
            (e) => e.id == history.episodeId,
          );
        } catch (_) {
          targetEpisode = detail.episodes.first;
        }
      } else {
        targetEpisode = detail.episodes.first;
      }

      // 🔥 DAPATKAN VIDEO URL
      String? videoUrl = targetEpisode.videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        videoUrl = detail.posterUrl ?? detail.imageUrl;
      }

      debugPrint('🎬 Video URL: $videoUrl');
      debugPrint('🎬 Initial Progress: ${history.progress}');

      // 🔥 BUILD EPISODE TITLE
      final episodeTitle = 'Episode ${targetEpisode.episodeNumber} - ${targetEpisode.title}';

      // 🔥 NAVIGASI KE STREAMING SCREEN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StreamingScreen(
            filmId: history.filmId,
            animeTitle: detail.title,
            episodeTitle: episodeTitle,
            videoUrl: videoUrl,
            initialProgress: history.progress,
          ),
        ),
      );

    } catch (e) {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat detail: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Riwayat',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.registerRed, size: 48),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Coba lagi', style: TextStyle(color: AppColors.accentCyan)),
                      ),
                    ],
                  ),
                )
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, color: AppColors.textSecondary.withOpacity(0.5), size: 64),
                          const SizedBox(height: 16),
                          const Text('Belum ada riwayat tontonan', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Mulai tonton anime favoritmu!', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final history = _history[index];
                        final anime = history.film;
                        if (anime == null) return const SizedBox.shrink();

                        final progressPercent = history.duration > 0
                            ? (history.progress / history.duration * 100)
                            : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                anime.imageUrl ?? '',
                                width: 60,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 80,
                                  color: AppColors.surfaceLight,
                                  child: const Icon(Icons.movie, color: Colors.grey, size: 30),
                                ),
                              ),
                            ),
                            title: Text(
                              anime.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progressPercent / 100,
                                          backgroundColor: Colors.grey.shade800,
                                          color: AppColors.accentCyan,
                                          minHeight: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${progressPercent.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: AppColors.accentCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, color: AppColors.textSecondary.withOpacity(0.6), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_formatTime(history.progress)} / ${_formatTime(history.duration)}',
                                      style: TextStyle(
                                        color: AppColors.textSecondary.withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentCyan.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Lanjutkan',
                                        style: TextStyle(
                                          color: AppColors.accentCyan,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.play_circle_outline, color: AppColors.accentCyan, size: 32),
                            onTap: () => _openStreaming(history),
                          ),
                        );
                      },
                    ),
    );
  }
}