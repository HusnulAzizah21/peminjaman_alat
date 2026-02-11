import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class StatusPeminjamanPage extends StatefulWidget {
  const StatusPeminjamanPage({super.key});

  @override
  State<StatusPeminjamanPage> createState() => _StatusPeminjamanPageState();
}

class _StatusPeminjamanPageState extends State<StatusPeminjamanPage> {
  bool isTabPengajuan = true;
  final c = Get.find<AppController>();

  // --- STREAM PENGAJUAN (Hanya yang sedang diproses / belum beres) ---
  Stream<List<Map<String, dynamic>>> _getStreamPengajuan() {
    final userId = c.userProfile['id_user'];
    return c.supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .order('id_pinjam', ascending: false)
        .map((data) => data.where((item) => 
            item['id_peminjam'] == userId && 
            // Filter: Jangan tampilkan yang sudah selesai
            item['status_transaksi'] != 'selesai'
        ).toList());
  }

  // --- STREAM PINJAMAN SAYA (Barang yang sedang di tangan user) ---
  Stream<List<Map<String, dynamic>>> _getStreamPinjamanAktif() {
    final userId = c.userProfile['id_user'];
    return c.supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .order('id_pinjam', ascending: false)
        .map((data) => data.where((item) => 
            item['id_peminjam'] == userId && 
            // Tampilkan yang sudah disetujui ATAU sedang dipinjam
            (item['status_transaksi'] == 'disetujui' || item['status_transaksi'] == 'dipinjam')
        ).toList());
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1F3C58);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PeminjamDrawer(currentPage: 'Peminjaman'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Status Peminjaman",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // CUSTOM TAB BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabItem("Pengajuan", isTabPengajuan, () {
                    setState(() => isTabPengajuan = true);
                  }),
                  _buildTabItem("Pinjaman saya", !isTabPengajuan, () {
                    setState(() => isTabPengajuan = false);
                  }),
                ],
              ),
            ),
          ),

          // KONTEN UTAMA
          Expanded(
            child: isTabPengajuan
                ? _buildRealListPengajuan(primaryColor)
                : _buildRealListPinjamanSaya(),
          ),
        ],
      ),
    );
  }

  // --- UI TAB 1: LIST PENGAJUAN ---
  Widget _buildRealListPengajuan(Color primaryColor) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getStreamPengajuan(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Belum ada riwayat pengajuan"));
        }

        final data = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            final status = item['status_transaksi'] ?? 'menunggu';
            
            // Perbaikan parsing tanggal created_at
            final String rawDate = item['created_at'] ?? DateTime.now().toIso8601String();
            final tglRequest = DateTime.parse(rawDate).toLocal();

            Color statusColor = primaryColor; // Biru untuk menunggu
            if (status == 'disetujui') statusColor = Colors.green;
            if (status == 'ditolak') statusColor = Colors.red;

            return _cardPengajuan(
                status.toString().capitalizeFirst!,
                statusColor,
                c.userProfile['nama'] ?? "User",
                DateFormat('dd MMM yyyy, HH:mm').format(tglRequest));
          },
        );
      },
    );
  }

  // --- UI TAB 2: PINJAMAN AKTIF ---
  Widget _buildRealListPinjamanSaya() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getStreamPinjamanAktif(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada pinjaman aktif"));
        }

        final data = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return _cardPinjamanAktif(
                "Peminjaman #${item['id_pinjam']}",
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['pengambilan'])),
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['tenggat'])));
          },
        );
      },
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildTabItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1F3C58) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardPengajuan(String status, Color color, String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pengajuan peminjaman", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 4, height: 40, color: color),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Status pengajuan Anda", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardPinjamanAktif(String title, String tglAmbil, String tglBalik) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade400, width: 1.5),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _dateBoxSmall("Ambil", tglAmbil),
            _dateBoxSmall("Tenggat", tglBalik),
          ],
        ),
        children: const [
          Padding(
            padding: EdgeInsets.all(15),
            child: Text("Silakan kembalikan alat tepat waktu. Barang yang sudah disetujui dapat diambil di petugas."),
          )
        ],
      ),
    );
  }

  Widget _dateBoxSmall(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}