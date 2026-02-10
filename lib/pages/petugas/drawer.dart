import 'package:aplikasi_peminjamanbarang/pages/petugas/beranda/beranda_petugas.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/laporan/laporan.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/peminjaman/halaman_utama.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/pengembalian.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';

class PetugasDrawer extends StatelessWidget {
  final String currentPage;
  const PetugasDrawer({super.key, required this.currentPage});

  @override
    Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    
    // Mengambil data dari userProfile yang diisi saat login manual
    // Pastikan key 'email' dan 'nama' sesuai dengan nama kolom di tabel users kamu
    final String userEmail = c.userProfile['email'] ?? "Email tidak tersedia";
    final String userName = c.userProfile['nama'] ?? "User";

    return Drawer(
      backgroundColor: Colors.white,
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
          // LIST MENU
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(
                  icon: Icons.home,
                  title: "Beranda",
                  isActive: currentPage == 'beranda',
                  onTap: () {
                    Get.back();
                    Get.off(() => const BerandaPetugas()); 
                  },
                ),
                _buildMenuItem(
                  icon: Icons.check_circle,
                  title: "Persetujuan",
                  isActive: currentPage == 'persetujuan',
                  onTap: () {
                    Get.back();
                    Get.off(() => const PersetujuanPage()); 
                  },
                ),
                _buildMenuItem(
                  icon: Icons.assignment_return,
                  title: "Pengembalian",
                  isActive: currentPage == 'pengembalian',
                  onTap: () {
                    Get.back();
                    Get.off(() => const DetailPengembalianSelesaiPage(data: {},)); 
                  },
                ),
                _buildMenuItem(
                  icon: Icons.bar_chart,
                  title: "Laporan",
                  isActive: currentPage == 'laporan',
                  onTap: () {
                    Get.back();
                    Get.off(() => const LaporanPage()); 
                  },
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

  // HELPER DENGAN EFEK AKTIF
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

  void _showLogoutDialog(BuildContext context, AppController c) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Keluar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
              const SizedBox(height: 15),
              const Text("Anda yakin ingin keluar dari aplikasi?", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF1F3C58))),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1F3C58)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Batal", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => c.logout(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F3C58),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text("Ya", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}