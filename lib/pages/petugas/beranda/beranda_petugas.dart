import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BerandaPetugas extends StatelessWidget {
  const BerandaPetugas({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1F3C58);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Beranda'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Beranda", 
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      // Panggil file drawer petugas kamu di sini
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROW STATISTIK (3 Card Atas)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Total Alat", "46", Icons.inventory_2, Colors.blue.shade900),
                _buildStatCard("Alat Tersedia", "39", Icons.check_circle, Colors.green),
                _buildStatCard("Alat Dipinjam", "7", Icons.handshake, Colors.orange), // Sesuai permintaan ganti alat rusak
              ],
            ),

            const SizedBox(height: 25),
            const Text("Navigasi Cepat", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 15),

            // TOMBOL CEPAT / NOTIFIKASI
            _buildNavTile(
              title: "Peminjaman",
              subtitle: "Cek pengajuan peminjaman terbaru",
              icon: Icons.notifications_active,
              iconColor: primaryColor,
              onTap: () => Get.toNamed('/peminjaman_petugas'),
            ),
            _buildNavTile(
              title: "Pengembalian",
              subtitle: "Cek pengembalian terbaru",
              icon: Icons.assignment_return,
              iconColor: Colors.green,
              onTap: () => Get.toNamed('/pengembalian_petugas'),
            ),
            _buildNavTile(
              title: "Pengembalian Terlambat",
              subtitle: "Cek alat yang perlu dikembalikan",
              icon: Icons.error,
              iconColor: Colors.red,
              onTap: () => Get.toNamed('/terlambat_petugas'),
            ),

            const SizedBox(height: 25),
            const Text("Ringkasan Aktivitas", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 15),

            // RINGKASAN AKTIVITAS (List Horizontal atau Vertical)
            _buildAktivitasCard("Monica", "Kamera DSLR", "Baru saja"),
            _buildAktivitasCard("Aura", "Tripod Takara", "10 menit yang lalu"),
            _buildAktivitasCard("Budi", "Lensa Canon", "1 jam yang lalu"),
          ],
        ),
      ),
    );
  }

  // WIDGET CARD STATISTIK
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // WIDGET NAVIGASI TILE
  Widget _buildNavTile({required String title, required String subtitle, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  // WIDGET RINGKASAN AKTIVITAS
  Widget _buildAktivitasCard(String user, String alat, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFF1F3C58), child: Icon(Icons.person, color: Colors.white, size: 20)),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text("Meminjam $alat", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}