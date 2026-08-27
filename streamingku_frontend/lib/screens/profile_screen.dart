import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart'; 
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
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
      final user = await ApiService.instance.getProfile();
      setState(() => _user = user);
    } catch (e) {
      setState(() => _error = 'Gagal memuat profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                      TextButton(onPressed: _load, child: const Text('Coba lagi')),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.surfaceLight,
                        // PERBAIKAN 1: Ganti avatarUrl menjadi avatar
                        backgroundImage: _user?.avatar != null
                            ? NetworkImage(_user!.avatar!)
                            : null,
                        // PERBAIKAN 2: Kondisi pengecekan avatar
                        child: _user?.avatar == null
                            ? const Icon(Icons.person, size: 44, color: AppColors.placeholder)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // PERBAIKAN 3: Ganti fullName menjadi name
                      Text(_user?.name ?? 'Nama User',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      // PERBAIKAN 4: Ganti username menjadi email (karena AppUser gak punya username)
                      Text(_user?.email ?? 'email@example.com',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.registerRed,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _logout,
                        child: const Text('LOGOUT', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
    );
  }
}