import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart'; // Sesuaikan dengan path controller Anda

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, required String currentPage});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();
    
    // Mengambil data user dari Supabase (atau fallback jika kosong)
    final user = c.supabase.auth.currentUser;
    final String userEmail = user?.email ?? "husnul@gmail.com";
    final String userName = userEmail.split('@')[0].capitalizeFirst ?? "Husnul";

    return Drawer(
      child: Column(
        children: [
          // HEADER PROFILE (Warna Biru Gelap sesuai Gambar)
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            width: double.infinity,
            color: const Color(0xFF1F3C58), // Warna Navy sesuai contoh
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor:Colors.white, // Warna background lingkaran
                  child: Text(
                    // Mengambil nama dari database, jika null pakai 'User'
                    // Lalu ambil karakter pertama dan jadikan huruf kapital
                    (c.supabase.auth.currentUser?.email ?? "U")[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1F3C58),// Warna huruf
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
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
                  isActive: Get.currentRoute == '/admin-beranda', // Logika aktif
                  onTap: () => Get.offNamed('/admin-beranda'),
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2,
                  title: "Manajemen Alat",
                  isActive: Get.currentRoute == '/manajemen-alat',
                  onTap: () => Get.offNamed('/manajemen-alat'),
                ),
                _buildMenuItem(
                  icon: Icons.assignment,
                  title: "Data Peminjaman",
                  isActive: Get.currentRoute == '/data-peminjaman',
                  onTap: () => Get.offNamed('/data-peminjaman'),
                ),
                _buildMenuItem(
                  icon: Icons.person,
                  title: "Manajemen Pengguna",
                  isActive: Get.currentRoute == '/manajemen-pengguna',
                  onTap: () => Get.offNamed('/manajemen-pengguna'),
                ),
                _buildMenuItem(
                  icon: Icons.history,
                  title: "Log Aktivitas",
                  isActive: Get.currentRoute == '/log-aktivitas',
                  onTap: () => Get.offNamed('/log-aktivitas'),
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: "Keluar",
                  onTap: () {
                    Get.dialog(
                      Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Keluar",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F3C58),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Anda yakin ingin keluar dari aplikasi?",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F3C58),
                                ),
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  // TOMBOL BATAL
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Get.back(),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF1F3C58)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        "Batal",
                                        style: TextStyle(
                                          color: Color(0xFF1F3C58),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  // TOMBOL YA
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => c.logout(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1F3C58),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text(
                                        "Ya",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat item menu yang sama persis
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[300] : Colors.transparent, // Background abu-abu jika aktif
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -2), // Merapatkan menu sesuai gambar
        leading: Icon(
          icon,
          color: color ?? const Color(0xFF1F3C58),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? const Color(0xFF1F3C58),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}