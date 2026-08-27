import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../theme/app_theme.dart';
import '../models/anime.dart';
import '../services/api_service.dart';

class StreamingScreen extends StatefulWidget {
  final int filmId;
  final String animeTitle;
  final String episodeTitle;
  final String? videoUrl;
  final int initialProgress; // 🔥 TAMBAHKAN

  const StreamingScreen({
    super.key,
    required this.filmId,
    required this.animeTitle,
    required this.episodeTitle,
    this.videoUrl,
    this.initialProgress = 0, // 🔥 DEFAULT 0
  });

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  List<Comment> _comments = [];
  final _commentCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  
  // Video Player
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _isVideoLoading = true;
  String? _videoError;

  // 🔥 HISTORY TRACKING
  int? _historyId;
  Timer? _progressTimer;
  int _currentProgress = 0;
  int _totalDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _initializeVideo();
    _createHistory();
    _startProgressTracking();
  }

  /// 🔥 Buat history record
  Future<void> _createHistory() async {
    try {
      final result = await ApiService.instance.addHistory(
        filmId: widget.filmId,
        episodeId: 1,
        progress: widget.initialProgress,
        duration: 0,
      );
      _historyId = result['id'];
      print('✅ History created: $_historyId');
    } catch (e) {
      print('⚠️ Gagal membuat history: $e');
    }
  }

  /// 🔥 Start progress tracking
  void _startProgressTracking() {
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        final position = _videoController!.value.position.inSeconds;
        final duration = _videoController!.value.duration.inSeconds;
        
        if (position > 0 && duration > 0) {
          _currentProgress = position;
          _totalDuration = duration;
          _updateProgress();
        }
      }
    });
  }

  /// 🔥 Update progress ke server
  Future<void> _updateProgress() async {
    if (_historyId == null) return;
    
    try {
      await ApiService.instance.updateHistory(
        historyId: _historyId!,
        progress: _currentProgress,
        duration: _totalDuration,
      );
    } catch (e) {
      // Silent error
    }
  }

  /// 🔥 Save progress akhir
  Future<void> _saveFinalProgress() async {
    if (_historyId == null) return;
    
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position.inSeconds;
      final duration = _videoController!.value.duration.inSeconds;
      
      if (position > 0) {
        try {
          await ApiService.instance.updateHistory(
            historyId: _historyId!,
            progress: position,
            duration: duration,
          );
          print('💾 Final progress saved: $position / $duration');
        } catch (e) {
          print('⚠️ Gagal save final progress: $e');
        }
      }
    }
  }

  void _initializeVideo() {
    final videoUrl = widget.videoUrl;
    
    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() {
        _isVideoLoading = false;
        _videoError = 'Video tidak tersedia';
      });
      return;
    }

    print('🎬 Memuat video: $videoUrl');
    print('⏩ Initial progress: ${widget.initialProgress} detik');
    
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );

    _videoController!.addListener(() {
      setState(() {});
    });

    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoLoading = false;
          _totalDuration = _videoController!.value.duration.inSeconds;
        });
        
        // 🔥 SET POSISI AWAL KE PROGRESS YANG DISIMPAN
        if (widget.initialProgress > 0 && widget.initialProgress < _totalDuration) {
          _videoController!.seekTo(Duration(seconds: widget.initialProgress));
          print('⏩ Seek to: ${widget.initialProgress} seconds');
        }
        
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          showControls: true,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          showOptions: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.accentCyan,
            handleColor: AppColors.accentCyan,
            backgroundColor: Colors.grey.shade700,
            bufferedColor: Colors.grey.shade400,
          ),
        );
        
        print('✅ Video siap diputar');
      }
    }).catchError((error) {
      print('❌ Error video: $error');
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = 'Gagal memuat video: ${error.toString()}';
        });
      }
    });
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final comments = await ApiService.instance.getComments(widget.filmId);
      setState(() => _comments = comments);
    } catch (_) {
      // biarkan kosong
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ApiService.instance.postComment(widget.filmId, text);
      _commentCtrl.clear();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _saveFinalProgress();
    _commentCtrl.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: _buildVideoPlayer(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.animeTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.episodeTitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Komentar',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Tambahkan komentar...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentCyan,
                                ),
                              )
                            : const Icon(Icons.send, color: AppColors.accentCyan),
                        onPressed: _sending ? null : _postComment,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.accentCyan),
                    )
                  else if (_comments.isEmpty)
                    const Text(
                      'Jadilah yang pertama berkomentar',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    )
                  else
                    ..._comments.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.surfaceLight,
                              child: Text(
                                c.userName.isNotEmpty ? c.userName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.userName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    c.text,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isVideoLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.accentCyan,
            ),
            SizedBox(height: 12),
            Text(
              'Memuat video...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_videoError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _videoError!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isVideoLoading = true;
                  _videoError = null;
                });
                _initializeVideo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_isVideoInitialized && _chewieController != null) {
      return Chewie(
        controller: _chewieController!,
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.white54,
            size: 64,
          ),
          SizedBox(height: 12),
          Text(
            'Video tidak tersedia',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}