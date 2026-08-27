import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/anime.dart';
import '../services/api_service.dart';
import '../widgets/anime_card.dart';
import 'search_screen.dart';
import 'detail_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'streaming_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  List<Anime> _history = [];
  List<Anime> _animeList = [];
  bool _loading = true;
  String? _error;
  bool _isLoadingHistory = false;
  bool _isLoadingAnime = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
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
      _isLoadingHistory = true;
      _isLoadingAnime = true;
    });

    debugPrint('🔄 Memuat data HomeScreen...');

    try {
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

      // Ambil history dengan progress
      try {
        debugPrint('📥 1. Mengambil history dengan progress...');
        final historyData = await ApiService.instance.getHistoryWithProgress();
        setState(() {
          _history = historyData.map((h) => h.film!).toList();
          _isLoadingHistory = false;
        });
        debugPrint('✅ History berhasil: ${_history.length} item');
      } catch (e) {
        debugPrint('⚠️ Error history: $e');
        setState(() {
          _history = [];
          _isLoadingHistory = false;
        });
      }

      // Ambil anime list
      try {
        debugPrint('📥 2. Mengambil anime list...');
        final animeList = await ApiService.instance.getAnimeList();
        setState(() {
          _animeList = animeList;
          _isLoadingAnime = false;
        });
        debugPrint('✅ Anime list berhasil: ${animeList.length} item');
      } catch (e) {
        debugPrint('❌ Error anime list: $e');
        setState(() {
          _isLoadingAnime = false;
        });
        rethrow;
      }

    } catch (e) {
      debugPrint('❌ Total error: $e');
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// 🔥 Buka streaming dari history dengan progress
  void _openHistoryStreaming(Anime anime) async {
    // 🔥 Ambil history detail dengan progress
    try {
      final historyList = await ApiService.instance.getHistoryWithProgress();
      final history = historyList.firstWhere(
        (h) => h.filmId == int.parse(anime.id),
        orElse: () => historyList.first,
      );
      
      debugPrint('🎬 ====== PLAY FROM HOME HISTORY ======');
      debugPrint('🎬 Film: ${anime.title}');
      debugPrint('🎬 Progress: ${history.progress} / ${history.duration}');
      debugPrint('🎬 =====================================');

      // 🔥 Ambil detail film untuk video URL
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.accentCyan),
        ),
      );

      final detail = await ApiService.instance.getAnimeDetail(anime.id);
      
      if (!mounted) {
        try { Navigator.pop(context); } catch (_) {}
        return;
      }
      try { Navigator.pop(context); } catch (_) {}

      if (detail.episodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada episode untuk film ini'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final targetEpisode = detail.episodes.first;
      String? videoUrl = targetEpisode.videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        videoUrl = detail.posterUrl ?? detail.imageUrl;
      }

      // 🔥 LANGSUNG KE STREAMING SCREEN DENGAN PROGRESS
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StreamingScreen(
            filmId: history.filmId,
            animeTitle: detail.title,
            episodeTitle: 'Episode ${targetEpisode.episodeNumber} - ${targetEpisode.title}',
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
            content: Text('Gagal memuat: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('❌ Error: $e');
    }
  }

  void _openDetail(Anime anime) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(animeId: anime.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('StreamingKu', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _loadData)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Section History
                      _buildSectionHeader('History', onSeeAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        );
                      }),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: _isLoadingHistory
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentCyan,
                                  ),
                                ),
                              )
                            : _history.isEmpty
                                ? const _EmptyInline(text: 'Belum ada riwayat tontonan')
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _history.length > 6 ? 6 : _history.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, i) {
                                      final anime = _history[i];
                                      return GestureDetector(
                                        onTap: () => _openHistoryStreaming(anime),
                                        child: AnimeThumbnail(
                                          anime: anime,
                                          onTap: () => _openHistoryStreaming(anime),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Section Anime List
                      _buildSectionHeader('Anime List'),
                      const SizedBox(height: 8),
                      _isLoadingAnime
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: CircularProgressIndicator(
                                  color: AppColors.accentCyan,
                                ),
                              ),
                            )
                          : _animeList.isEmpty
                              ? const _EmptyInline(text: 'Belum ada anime tersedia')
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _animeList.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemBuilder: (context, i) {
                                    final anime = _animeList[i];
                                    return AnimeGridCard(
                                      anime: anime,
                                      onTap: () => _openDetail(anime),
                                    );
                                  },
                                ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'Lihat semua',
              style: TextStyle(color: AppColors.accentCyan, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final String text;
  const _EmptyInline({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 40),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}