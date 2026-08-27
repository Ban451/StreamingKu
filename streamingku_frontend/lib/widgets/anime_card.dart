import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/anime.dart';

/// Kotak thumbnail dengan silang (X) sebagai placeholder gambar,
/// persis seperti pada wireframe, sekaligus menampilkan gambar asli
/// jika [anime.imageUrl] sudah tersedia dari API.
class AnimeThumbnail extends StatelessWidget {
  final Anime anime;
  final double size;
  final VoidCallback? onTap;

  const AnimeThumbnail({
    super.key,
    required this.anime,
    this.size = 90,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: anime.imageUrl != null && anime.imageUrl!.isNotEmpty
            ? Image.network(
                anime.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _PlaceholderCross(),
              )
            : const _PlaceholderCross(),
      ),
    );
  }
}

class _PlaceholderCross extends StatelessWidget {
  const _PlaceholderCross();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CrossPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.placeholder
      ..strokeWidth = 1;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kartu untuk grid anime (Home, Search, Library) dengan judul di bawah gambar.
class AnimeGridCard extends StatelessWidget {
  final Anime anime;
  final VoidCallback? onTap;

  const AnimeGridCard({super.key, required this.anime, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: anime.imageUrl != null && anime.imageUrl!.isNotEmpty
                  ? Image.network(anime.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _PlaceholderCross())
                  : const _PlaceholderCross(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            anime.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Baris item riwayat: thumbnail + judul + "terakhir: episode.."
class HistoryListItem extends StatelessWidget {
  final Anime anime;
  final VoidCallback? onTap;

  const HistoryListItem({super.key, required this.anime, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimeThumbnail(anime: anime, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(anime.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    'terakhir: ${anime.lastEpisode ?? "episode.."}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
