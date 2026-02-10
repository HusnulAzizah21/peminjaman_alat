import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/laporan/laporan_pdf.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// ────────────────────────────────────────────────
// 1. CONTROLLER (State & Business Logic)
// ────────────────────────────────────────────────
class LaporanMingguanController extends GetxController {
  final AppController appCtrl = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);

  RxList<Map<String, dynamic>> dataPeminjaman = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLaporanMingguan();
  }

  /// Mengambil data peminjaman 7 hari terakhir dari Supabase
  Future<void> fetchLaporanMingguan() async {
    try {
      isLoading.value = true;

      final semingguLalu = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

      final response = await appCtrl.supabase
          .from('peminjaman')
          .select('*, users!peminjaman_id_peminjam_fkey(nama), detail_peminjaman(alat(nama_alat))')
          .gte('pengambilan', semingguLalu)
          .order('pengambilan', ascending: false);

      dataPeminjaman.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error fetch laporan: $e");
      Get.snackbar("Error", "Gagal memuat data laporan");
    } finally {
      isLoading.value = false;
    }
  }

  /// Hitung statistik yang dibutuhkan untuk UI dan PDF
  Map<String, dynamic> hitungStatistik() {
    final list = dataPeminjaman;

    // Total peminjaman
    final total = list.length;

    // Total terlambat (belum selesai & melewati tenggat)
    final terlambat = list.where((e) {
      final tenggatStr = e['tenggat']?.toString();
      if (tenggatStr == null) return false;
      try {
        return DateTime.now().isAfter(DateTime.parse(tenggatStr)) &&
               e['status_transaksi'] != 'selesai';
      } catch (_) {
        return false;
      }
    }).length;

    // Alat terpopuler (berdasarkan frekuensi muncul di detail)
    final alatCount = <String, int>{};
    for (var item in list) {
      final details = item['detail_peminjaman'] as List?;
      if (details != null) {
        for (var d in details) {
          final nama = d['alat']?['nama_alat']?.toString() ?? "Alat Tidak Diketahui";
          alatCount[nama] = (alatCount[nama] ?? 0) + 1;
        }
      }
    }
    final sortedAlat = alatCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final alatPopuler = sortedAlat.isNotEmpty ? sortedAlat.first.key : "-";

    return {
      'total': total,
      'terlambat': terlambat,
      'alatPopuler': alatPopuler,
    };
  }

  /// Format tanggal pendek (dd MMM)
  String formatTanggal(dynamic value) {
    if (value == null) return "?";
    try {
      return DateFormat('dd MMM').format(DateTime.parse(value.toString()));
    } catch (_) {
      return "?";
    }
  }

  /// Ambil nama alat pertama dari detail_peminjaman
  String getNamaAlatPertama(Map<String, dynamic> item) {
    final details = item['detail_peminjaman'] as List?;
    if (details == null || details.isEmpty) return "-";
    return details.first['alat']?['nama_alat']?.toString() ?? "-";
  }

  /// Ambil nama peminjam
  String getNamaPeminjam(Map<String, dynamic> item) {
    return item['users']?['nama']?.toString() ?? "User Tidak Diketahui";
  }

  /// Status dengan huruf kapital pertama
  String formatStatus(String? status) {
    return (status ?? "-").capitalizeFirst!;
  }
}

// ────────────────────────────────────────────────
// 2. PAGE (UI Utama - Stateless)
// ────────────────────────────────────────────────
class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LaporanMingguanController());

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Laporan'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Laporan Mingguan",
          style: TextStyle(color: controller.primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = controller.hitungStatistik();
        final data = controller.dataPeminjaman;

        return Column(
          children: [
            // Bagian statistik ringkasan
            _StatistikSection(stats: stats, primaryColor: controller.primaryColor),

            const Divider(thickness: 1, indent: 15, endIndent: 15),

            // Judul daftar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.list_alt, size: 18, color: controller.primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    "Daftar Aktivitas Peminjaman",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Daftar item
            Expanded(
              child: data.isEmpty
                  ? const Center(child: Text("Tidak ada data minggu ini"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        return _LaporanItemCard(
                          nama: controller.getNamaPeminjam(item),
                          alat: controller.getNamaAlatPertama(item),
                          tanggal: "${controller.formatTanggal(item['pengambilan'])} - "
                              "${controller.formatTanggal(item['tenggat'])}",
                          status: controller.formatStatus(item['status_transaksi']),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: _CetakPdfButton(),
    );
  }
}

// ────────────────────────────────────────────────
// 3. WIDGET: Statistik Ringkasan (3 Card)
// ────────────────────────────────────────────────
class _StatistikSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Color primaryColor;

  const _StatistikSection({required this.stats, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          _StatCard(label: "Total", value: stats['total'].toString(), color: Colors.blue),
          const SizedBox(width: 8),
          _StatCard(label: "Telat", value: stats['terlambat'].toString(), color: Colors.red),
          const SizedBox(width: 8),
          _StatCard(
            label: "Populer",
            value: stats['alatPopuler'],
            color: Colors.orange,
            isLong: true,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLong;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.isLong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: isLong ? 2 : 1,
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
                color: color,
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
}

// ────────────────────────────────────────────────
// 4. WIDGET: Item Daftar Peminjaman
// ────────────────────────────────────────────────
class _LaporanItemCard extends StatelessWidget {
  final String nama;
  final String alat;
  final String tanggal;
  final String status;

  const _LaporanItemCard({
    required this.nama,
    required this.alat,
    required this.tanggal,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool selesai = status == "Selesai";

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
          const CircleAvatar(
            backgroundColor: Color(0xFF1F3C58),
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(alat, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(tanggal, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selesai ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selesai ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// 5. WIDGET: Tombol Cetak PDF (FAB)
// ────────────────────────────────────────────────
class _CetakPdfButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LaporanMingguanController>();

    return FloatingActionButton.extended(
      onPressed: () async {
        if (controller.dataPeminjaman.isEmpty) {
          Get.snackbar("Peringatan", "Data kosong, tidak bisa cetak");
          return;
        }

        try {
          await LaporanService.cetakLaporanMingguan(
            dataPeminjaman: controller.dataPeminjaman,
          );
          Get.snackbar("Sukses", "Laporan PDF sedang diproses", backgroundColor: Colors.green);
        } catch (e) {
          debugPrint("Error cetak PDF: $e");
          Get.snackbar("Error", "Gagal membuat PDF: $e", backgroundColor: Colors.red);
        }
      },
      backgroundColor: controller.primaryColor,
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text("Cetak PDF"),
    );
  }
}