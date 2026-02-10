import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/peminjaman/halaman_utama.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/pengembalian.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ────────────────────────────────────────────────
// 1. CONTROLLER (State & Business Logic)
// ────────────────────────────────────────────────
class BerandaPetugasController extends GetxController {
  final AppController appCtrl = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);

  // Format waktu ISO ke format yang lebih mudah dibaca
  String formatWaktu(String? isoString) {
    if (isoString == null) return "-";
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM, HH:mm').format(date);
    } catch (e) {
      return isoString;
    }
  }
}

// ────────────────────────────────────────────────
// 2. PAGE (UI Utama - StatelessWidget)
// ────────────────────────────────────────────────
class BerandaPetugas extends StatelessWidget {
  const BerandaPetugas({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BerandaPetugasController());

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Beranda'),
      appBar: _buildAppBar(controller.primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian statistik real-time (jumlah alat)
            _StatistikAlatSection(controller: controller),

            const SizedBox(height: 25),
            _buildSectionTitle("Navigasi Cepat", controller.primaryColor),
            const SizedBox(height: 15),

            // Tombol navigasi cepat
            _NavigasiCepatSection(controller: controller),

            const SizedBox(height: 25),
            _buildSectionTitle("Aktivitas Terbaru", controller.primaryColor),
            const SizedBox(height: 15),

            // Ringkasan aktivitas terbaru (5 terakhir)
            _AktivitasTerbaruSection(controller: controller),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(Color primaryColor) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        "Beranda",
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: primaryColor),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }
}

// ────────────────────────────────────────────────
// 3. WIDGET KHUSUS: Statistik Alat (Total, Tersedia, Dipinjam)
// ────────────────────────────────────────────────
class _StatistikAlatSection extends StatelessWidget {
  final BerandaPetugasController controller;

  const _StatistikAlatSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.appCtrl.supabase.from('alat').stream(primaryKey: ['id_alat']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final daftarAlat = snapshot.data ?? [];

        final int totalAlat = daftarAlat.length;
        final int tersedia = daftarAlat.where((e) => (e['stok_total'] ?? 0) > 0).length;
        final int dipinjam = daftarAlat.where((e) => (e['stok_total'] ?? 0) == 0).length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(title: "Total Alat", count: totalAlat.toString(), icon: Icons.inventory_2, color: Colors.blue.shade900),
            _StatCard(title: "Tersedia", count: tersedia.toString(), icon: Icons.check_circle, color: Colors.green),
            _StatCard(title: "Dipinjam", count: dipinjam.toString(), icon: Icons.handshake, color: Colors.orange),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────
// 4. WIDGET KHUSUS: Kartu Statistik Kecil
// ────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

// ────────────────────────────────────────────────
// 5. WIDGET KHUSUS: Navigasi Cepat (Persetujuan & Pengembalian)
// ────────────────────────────────────────────────
class _NavigasiCepatSection extends StatelessWidget {
  final BerandaPetugasController controller;

  const _NavigasiCepatSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NavTile(
          title: "Persetujuan",
          subtitle: "Cek pengajuan peminjaman terbaru",
          icon: Icons.notifications_active,
          iconColor: controller.primaryColor,
          onTap: () {
            Get.back();
            Get.off(() => const PersetujuanPage());
          },
        ),
        _NavTile(
          title: "Pengembalian",
          subtitle: "Proses alat yang kembali",
          icon: Icons.assignment_return,
          iconColor: Colors.green,
          onTap: () {
            Get.back();
            Get.off(() => PetugasPengembalianPage());
          },
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

// ────────────────────────────────────────────────
// 6. WIDGET KHUSUS: Daftar Aktivitas Terbaru (5 terakhir)
// ────────────────────────────────────────────────
class _AktivitasTerbaruSection extends StatelessWidget {
  final BerandaPetugasController controller;

  const _AktivitasTerbaruSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.appCtrl.supabase
          .from('peminjaman')
          .select('*, users!peminjaman_id_peminjam_fkey(nama)')
          .order('pengambilan', ascending: false)
          .limit(5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Belum ada aktivitas terbaru", style: TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }

        return Column(
          children: snapshot.data!.map((item) {
            final String namaUser = item['users']?['nama'] ?? "User Unknown";
            final String status = item['status_transaksi'] ?? "menunggu";
            final String waktu = controller.formatWaktu(item['pengambilan']);

            return _AktivitasCard(user: namaUser, desc: "Status: $status", time: waktu);
          }).toList(),
        );
      },
    );
  }
}

class _AktivitasCard extends StatelessWidget {
  final String user;
  final String desc;
  final String time;

  const _AktivitasCard({
    required this.user,
    required this.desc,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
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