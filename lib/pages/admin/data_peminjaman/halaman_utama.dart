import 'package:aplikasi_peminjamanbarang/pages/admin/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

// ==========================================
// HALAMAN DATA PEMINJAMAN 
// ==========================================
class AdminDataPeminjamanPage extends StatefulWidget {
  const AdminDataPeminjamanPage({super.key});

  @override
  State<AdminDataPeminjamanPage> createState() => _AdminDataPeminjamanPageState();
}

class _AdminDataPeminjamanPageState extends State<AdminDataPeminjamanPage> {
  final c = Get.find<AppController>();

  // State untuk mengontrol tab filter (Aktif vs Selesai)
  bool isTabPeminjaman = true;

  // Warna utama tema aplikasi
  final Color primaryColor = const Color(0xFF1F3C58);

  // ==========================================
  // 1. FUNGSI: STREAM REALTIME SUPABASE
  // ==========================================
  Stream<List<Map<String, dynamic>>> _getAdminStream() {
    return c.supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .order('id_pinjam', ascending: false);
  }

  // ==========================================
  // 2. FUNGSI: RELASI TABEL (GET USER NAME)
  // ==========================================
  Future<String> _getNamaPeminjam(String? userId) async {
    if (userId == null || userId == '-') return "User Anonim";
    try {
      final res = await c.supabase
          .from('users')
          .select('nama')
          .eq('id_user', userId)
          .maybeSingle();
      return res != null ? (res['nama']?.toString() ?? "Tanpa Nama") : "User Tidak Ditemukan";
    } catch (e) {
      return "Gagal Memuat Nama";
    }
  }

  // ==========================================
  // 3. FUNGSI: FORMAT TANGGAL
  // ==========================================
  String formatTanggal(Map item) {
    final raw = item['pengambilan'] ?? 
                item['created_at'] ?? 
                item['tenggat'];

    if (raw == null) return "-";

    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('dd MMM yyyy - HH:mm').format(dt.toLocal());
    } catch (e) {
      return raw.toString();
    }
  }

  // ==========================================
  // 4. FUNGSI: HAPUS DATA
  // ==========================================
  Future<void> _hapusData(int id) async {
    try {
      await c.supabase.from('peminjaman').delete().eq('id_pinjam', id);
      Get.snackbar(
        "Berhasil",
        "Data peminjaman telah dihapus dari sistem",
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Gagal", "Error: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // ==========================================
  // 5. REFRESH (PENGGANTI AUTOREF)
  // ==========================================
  Future<void> autoRefresh() async {
    setState(() {});
    return await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(currentPage: 'Data Peminjam'),
      appBar: AppBar(
        title: const Text(
          "Data Peminjam",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F3C58)),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1F3C58)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(width),

            // Tab Bar
            _buildCustomTabBar(width),

            // List Data Realtime dengan RefreshIndicator yang benar
            Expanded(
              child: RefreshIndicator(
                onRefresh: autoRefresh,
                color: primaryColor,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getAdminStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text("Terjadi kesalahan sinkronisasi data"));
                    }

                    final allData = snapshot.data ?? [];

                    final filteredData = isTabPeminjaman
                        ? allData.where((item) => item['status_transaksi'] != 'selesai').toList()
                        : allData.where((item) => item['status_transaksi'] == 'selesai').toList();

                    if (filteredData.isEmpty) {
                      // Gunakan ListView agar pull-to-refresh tetap berfungsi meski data kosong
                      return ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text("Tidak ada data ditemukan", style: TextStyle(color: Colors.grey))),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 15),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) => _buildCardItem(filteredData[index], width),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildSearchBar(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.blueGrey.shade100),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: "Pencarian data peminjaman...",
            prefixIcon: Icon(Icons.search, color: Color(0xFF1F3C58)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(double width) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 10),
      child: Row(
        children: [
          _tabButton("Peminjaman Aktif", isTabPeminjaman, () => setState(() => isTabPeminjaman = true)),
          const SizedBox(width: 10),
          _tabButton("Selesai", !isTabPeminjaman, () => setState(() => isTabPeminjaman = false)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> item, double width) {
    String status = (item['status_transaksi'] ?? 'menunggu').toString();
    String? idUser = item['id_peminjam']?.toString();

    Color statusColor = Colors.orange;
    if (status == 'disetujui') statusColor = Colors.green;
    if (status == 'ditolak') statusColor = Colors.red;
    if (status == 'selesai') statusColor = const Color(0xFF4C6793);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4, height: 40,
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getNamaPeminjam(idUser),
                        builder: (context, snapshot) {
                          return SizedBox(
                            width: width * 0.5,
                            child: Text(
                              snapshot.data ?? "Loading...",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 3),
                      Text("ID Pinjam: #${item['id_pinjam']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(formatTanggal(item), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              IconButton(
                onPressed: () => _confirmDelete(item['id_pinjam']),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            ],
          )
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    Get.defaultDialog(
      title: "Hapus Data",
      titleStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      middleText: "Apakah Anda yakin ingin menghapus data ini?",
      textConfirm: "Ya",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _hapusData(id);
      },
    );
  }
}