import 'package:aplikasi_peminjamanbarang/pages/admin/beranda/beranda_admin.dart';
import 'package:aplikasi_peminjamanbarang/pages/admin/data_peminjaman/halaman_utama.dart';
import 'package:aplikasi_peminjamanbarang/pages/admin/log_aktivitas/halaman_log.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart'; 
import 'package:aplikasi_peminjamanbarang/pages/admin/manajemen_alat/halaman_utama.dart';
import 'package:aplikasi_peminjamanbarang/pages/admin/manajemen_user/halaman_utama.dart';

class AdminDrawer extends StatelessWidget {
  final String currentPage;
  const AdminDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    
    // AMBIL DATA DARI userProfile (Hasil login manual di AppController)
    final userData = c.userProfile;
    final String userEmail = userData['email'] ?? "admin@gmail.com";
    final String userName = userData['nama'] ?? "Administrator";

    return Drawer(
      child: Column(
        children: [
          // HEADER PROFILE
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
                    userName.isNotEmpty ? userName[0].toUpperCase() : "A",
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

          // LIST MENU
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(
                  icon: Icons.home,
                  title: "Beranda",
                  isActive: currentPage == 'Beranda',
                  onTap: () {
                    Get.off(() => const AdminBerandaPage());
                  }
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2,
                  title: "Manajemen Alat",
                  isActive: currentPage == 'Manajemen Alat',
                  onTap: () {
                    Get.back();
                    Get.off(() => const AdminPage()); 
                  },
                ),
                _buildMenuItem(
                  icon: Icons.assignment,
                  title: "Data Peminjaman",
                  isActive: currentPage == 'Data Peminjaman',
                  onTap: () {
                    Get.back();
                    Get.off(() => const DataPeminjamanAdminPage());
                    },
                ),
                _buildMenuItem(
                  icon: Icons.person,
                  title: "Manajemen Pengguna",
                  isActive: currentPage == 'Manajemen Pengguna',
                  onTap: () {
                    Get.back();
                    Get.off(() => const ManajemenPenggunaPage()); 
                  },
                ),
                _buildMenuItem(
                  icon: Icons.history,
                  title: "Log Aktivitas",
                  isActive: currentPage == 'Log Aktivitas',
                  onTap: () {
                    Get.back();
                    Get.off(() => const LogAktivitasPage ());
                  } 
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: "Keluar",
                  onTap: () {
                    Get.back(); // Tutup Drawer
                    _showLogoutDialog(c);
                  },
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

  void _showLogoutDialog(AppController c) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Keluar", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
        content: const Text("Anda yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Tutup Dialog
              c.logout(); // Panggil fungsi logout di controller
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F3C58)),
            child: const Text("Ya", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}