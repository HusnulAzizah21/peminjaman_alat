import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'admin/admin_page.dart';
import 'petugas/petugas_page.dart';
import 'peminjam/beranda.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 3));

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      Get.offAll(() => LoginPage());
    } else {
      try {
        final supabase = Supabase.instance.client;

        // DIUBAH: Dari 'users' menjadi 'profiles' agar sama dengan Controller
        final profile = await supabase
            .from('users')
            .select()
            .eq('id_user', session.user.id)
            .maybeSingle();

        if (profile == null) {
          Get.offAll(() => LoginPage());
          return;
        }

        final role = profile['role'];

        if (role == 'Admin') {
          Get.offAll(() => const AdminPage());
        } else if (role == 'Petugas') {
          Get.offAll(() => const PetugasPage());
        } else {
          Get.offAll(() => const PeminjamPage());
        }
      } catch (e) {
        // Jika error (koneksi/data), arahkan ke login
        Get.offAll(() => LoginPage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo_sibrantas.png',
          width: 90,
          height: 90,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'SiBrantas',
              style: TextStyle(color: Color(0xFF1F3C58), fontSize: 24, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }
}