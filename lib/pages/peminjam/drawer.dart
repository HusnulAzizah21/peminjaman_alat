import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/beranda.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/peminjaman.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/riwayat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MySharedDrawer extends StatelessWidget {
  final String currentPage;
  const MySharedDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    final user = c.supabase.auth.currentUser;
    final String userEmail = user?.email ?? "User@gmail.com";
    final String userName = userEmail.split('@')[0].capitalizeFirst ?? "User";

    return Drawer(
      child: Column(
        children: [
          // HEADER PROFILE (Biru Gelap)
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
            width: double.infinity,
            color: const Color(0xFF1F3C58),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/avatar.png'),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userEmail,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
          
          // MENU ITEMS
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),
                _buildMenuItem(
                  icon: Icons.home_outlined,
                  title: "Beranda",
                  isActive: currentPage == 'beranda',
                  onTap: () => Get.offAll(() => const PeminjamPage()),
                ),
                _buildMenuItem(
                  icon: Icons.add_box_outlined,
                  title: "Peminjaman",
                  isActive: currentPage == 'peminjaman',
                  onTap: () => Get.offAll(() => const PeminjamanPage()),
                ),
                _buildMenuItem(
                  icon: Icons.history,
                  title: "Riwayat",
                  isActive: currentPage == 'riwayat',
                  onTap: () => Get.offAll(() => const RiwayatPage()),
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: "Keluar",
                  onTap: () => c.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[200] : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1F3C58)),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      ),
    );
  }
}