import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/anime.dart';
import '../services/api_service.dart';
import '../widgets/anime_card.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  List<Anime> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  void _onChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.instance.searchAnime(query);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Cari anime...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Ketik judul anime untuk mencari',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ditemukan hasil',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, i) {
        final anime = _results[i];
        return AnimeGridCard(
          anime: anime,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DetailScreen(animeId: anime.id)),
            );
          },
        );
      },
    );
  }
}