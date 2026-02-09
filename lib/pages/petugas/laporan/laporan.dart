import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/laporan/laporan_pdf.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final Color primaryColor = const Color(0xFF1F3C58);
  final c = Get.find<AppController>();
  List<Map<String, dynamic>> _currentData = [];

  Future<List<Map<String, dynamic>>> _getLaporanMingguan() async {
    try {
      final semingguLalu = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      
      final response = await c.supabase
          .from('peminjaman')
          .select('*, users!peminjaman_id_peminjam_fkey(nama), detail_peminjaman(alat(nama_alat))')
          .gte('pengambilan', semingguLalu)
          .order('pengambilan', ascending: false);
      
      _currentData = List<Map<String, dynamic>>.from(response);
      return _currentData;
    } catch (e) {
      debugPrint("Error Laporan: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Laporan'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Laporan Mingguan",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getLaporanMingguan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          
          // Logika Statistik
          int total = data.length;
          int terlambat = data.where((e) {
            if (e['tenggat'] == null) return false;
            return DateTime.now().isAfter(DateTime.parse(e['tenggat'])) && e['status_transaksi'] != 'selesai';
          }).length;

          // Logika Alat Terpopuler
          Map<String, int> hitungAlat = {};
          for (var item in data) {
            for (var detail in item['detail_peminjaman']) {
              String nama = detail['alat']['nama_alat'];
              hitungAlat[nama] = (hitungAlat[nama] ?? 0) + 1;
            }
          }
          var urutAlat = hitungAlat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          String alatPopuler = urutAlat.isNotEmpty ? urutAlat.first.key : "-";

          return Column(
            children: [
              // --- 1. CARD STATISTIK SEJAJAR (ATAS) ---
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    _buildStatCard("Total", total.toString(), Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard("Telat", terlambat.toString(), Colors.red),
                    const SizedBox(width: 8),
                    _buildStatCard("Populer", alatPopuler, Colors.orange, isLong: true),
                  ],
                ),
              ),

              const Divider(thickness: 1, indent: 15, endIndent: 15),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.list_alt, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text("Daftar Aktivitas Peminjaman", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),

              // --- 2. DAFTAR ITEM ---
              Expanded(
                child: data.isEmpty 
                ? const Center(child: Text("Tidak ada data minggu ini"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      String namaAlat = item['detail_peminjaman'].isNotEmpty 
                          ? item['detail_peminjaman'][0]['alat']['nama_alat'] : "-";
                      return _buildLaporanItem(
                        item['users']?['nama'] ?? "User", 
                        namaAlat, 
                        "${_fmt(item['pengambilan'])} - ${_fmt(item['tenggat'])}", 
                        item['status_transaksi'].toString().capitalizeFirst!
                      );
                    },
                  ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            if (_currentData.isEmpty) {
              Get.snackbar("Peringatan", "Data kosong, tidak bisa cetak");
              return;
            }
            print("Memulai proses cetak..."); // Cek di terminal
            await LaporanService.cetakLaporan(_currentData);
            print("Proses cetak selesai.");
          } catch (e) {
            print("Error Cetak PDF: $e"); // Ini akan memberitahu letak errornya
            Get.snackbar("Error", "Gagal membuat PDF: $e", 
                backgroundColor: Colors.red, colorText: Colors.white);
          }
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Cetak PDF"),
      ),
    );
  }

  // --- WIDGETS ---

  // Widget Stat Card yang fleksibel
  Widget _buildStatCard(String label, String value, Color color, {bool isLong = false}) {
    return Expanded(
      flex: isLong ? 2 : 1, // Berikan ruang lebih untuk nama alat terpopuler
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value, 
              style: TextStyle(
                fontSize: isLong ? 12 : 16, 
                fontWeight: FontWeight.bold, 
                color: color
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic date) {
    if (date == null) return "?";
    return DateFormat('dd MMM').format(DateTime.parse(date.toString()));
  }

  Widget _buildLaporanItem(String nama, String alat, String tgl, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Color(0xFF1F3C58), child: Icon(Icons.person, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(alat, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(tgl, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == "Selesai" ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Text(status, 
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                color: status == "Selesai" ? Colors.green : Colors.orange
              )
            ),
          ),
        ],
      ),
    );
  }
}