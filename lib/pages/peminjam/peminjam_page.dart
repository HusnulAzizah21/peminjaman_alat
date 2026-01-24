import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';

class PeminjamPage extends StatelessWidget {
  const PeminjamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    
    // Mengambil data user dari session supabase yang sedang aktif
    final user = c.supabase.auth.currentUser;
    final String userEmail = user?.email ?? "User@gmail.com";
    // Untuk nama, biasanya diambil dari data profile, di sini kita ambil bagian depan email sebagai placeholder
    final String userName = userEmail.split('@')[0].capitalizeFirst ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Peminjam"),
        // Tombol menu otomatis muncul jika ada drawer
      ),
      // --- TAMBAHKAN DRAWER DI SINI ---
      drawer: Drawer(
        child: Column(
          children: [
            // BAGIAN HEADER PROFILE (Biru Gelap)
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
              width: double.infinity,
              color: const Color(0xFF1F3C58), // Warna biru gelap sesuai gambar
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/avatar.png'), // Pastikan aset tersedia
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // BAGIAN MENU ITEMS
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    icon: Icons.home,
                    title: "Beranda",
                    isActive: true, // Beranda aktif sesuai gambar
                    onTap: () => Get.back(),
                  ),
                  _buildMenuItem(
                    icon: Icons.add_box,
                    title: "Peminjaman",
                    onTap: () {
                      // Navigasi ke halaman peminjaman
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: "Riwayat",
                    onTap: () {
                      // Navigasi ke halaman riwayat
                    },
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
      ),
      body: const Center(
        child: Text("Halaman Peminjam", style: TextStyle(fontSize: 20)),
      ),
    );
  }

  // Widget pembantu untuk membuat list item menu
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
        leading: Icon(
          icon,
          color: const Color(0xFF1F3C58),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1F3C58),
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}