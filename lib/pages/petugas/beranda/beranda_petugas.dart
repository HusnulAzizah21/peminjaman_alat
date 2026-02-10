import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/peminjaman/halaman_utama.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/pengembalian.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BerandaPetugas extends StatelessWidget {
  const BerandaPetugas({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1F3C58);
    final c = Get.find<AppController>();

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: STATISTIK REAL-TIME ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('alat').stream(primaryKey: ['id_alat']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final daftarAlat = snapshot.data ?? [];
                
                // Perbaikan Error '>' dengan pengecekan null (null safety)
                final int totalAlat = daftarAlat.length;
                final int tersedia = daftarAlat.where((e) => (e['stok_total'] ?? 0) > 0).length;
                final int dipinjam = daftarAlat.where((e) => (e['stok_total'] ?? 0) == 0).length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard("Total Alat", totalAlat.toString(), Icons.inventory_2, Colors.blue.shade900),
                    _buildStatCard("Tersedia", tersedia.toString(), Icons.check_circle, Colors.green),
                    _buildStatCard("Habis", dipinjam.toString(), Icons.handshake, Colors.orange),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),
            const Text("Navigasi Cepat", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 15),

            // Tombol Navigasi
            _buildNavTile(
              title: "Persetujuan",
              subtitle: "Cek pengajuan peminjaman terbaru",
              icon: Icons.notifications_active,
              iconColor: primaryColor,
              onTap: () {
                    Get.back();
                    Get.off(() => const PersetujuanPage()); 
                  },
            ),
            _buildNavTile(
              title: "Pengembalian",
              subtitle: "Proses alat yang kembali",
              icon: Icons.assignment_return,
              iconColor: Colors.green,
              onTap: () {
                    Get.back();
                    Get.off(() => const PetugasPengembalianPage()); 
                  },
            ),

            const SizedBox(height: 25),
            const Text("Aktivitas Terbaru", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 15),

            // --- BAGIAN 2: RINGKASAN AKTIVITAS ASLI ---
            // Mengambil 5 data peminjaman terbaru dengan Join ke tabel Users
            FutureBuilder<List<Map<String, dynamic>>>(
              future: c.supabase
                  .from('peminjaman')
                  .select('*, users!peminjaman_id_peminjam_fkey(nama)')
                  .order('pengambilan', ascending: false)
                  .limit(5),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada aktivitas terbaru", style: TextStyle(fontSize: 12, color: Colors.grey)));
                }

                return Column(
                  children: snapshot.data!.map((item) {
                    final String namaUser = item['users']?['nama'] ?? "User Unknown";
                    final String status = item['status_transaksi'] ?? "menunggu";
                    final String waktu = _formatWaktu(item['pengambilan']);

                    return _buildAktivitasCard(namaUser, "Status: $status", waktu);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatWaktu(String? isoString) {
    if (isoString == null) return "-";
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM, HH:mm').format(date);
    } catch (e) {
      return isoString;
    }
  }

  // --- UI COMPONENTS (SAMA SEPERTI SEBELUMNYA) ---
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNavTile({required String title, required String subtitle, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(icon, color: iconColor)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildAktivitasCard(String user, String desc, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 15, backgroundColor: Color(0xFF1F3C58), child: Icon(Icons.person, size: 15, color: Colors.white)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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