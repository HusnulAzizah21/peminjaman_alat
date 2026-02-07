import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/beranda.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/peminjaman.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/riwayat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PeminjamDrawer extends StatelessWidget {
  final String currentPage;
  const PeminjamDrawer({super.key, required this.currentPage});

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
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            width: double.infinity,
            color: const Color(0xFF1F3C58),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : "U"),
                    style: const TextStyle(
                      color: Color(0xFF1F3C58),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          // MENU ITEMS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(
                  icon: Icons.home,
                  title: "Beranda",
                  isActive: currentPage == 'beranda',
                  onTap: () => Get.offAll(() => const PeminjamPage()),
                ),
                _buildMenuItem(
                  icon: Icons.add_box,
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
                  onTap: () => _showLogoutDialog(context, c),
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
    const Color primaryColor = Color(0xFF1F3C58);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        // EFEK BACKGROUND AKTIF
        color: isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(
          icon,
          color: isActive ? primaryColor : primaryColor.withOpacity(0.7),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppController c) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Keluar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
              const SizedBox(height: 10),
              const Text("Anda yakin ingin keluar dari aplikasi?", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1F3C58))),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1F3C58)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Batal", style: TextStyle(color: Color(0xFF1F3C58))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => c.logout(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F3C58),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Ya", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}