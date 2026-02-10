import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../drawer.dart';

// ────────────────────────────────────────────────
// 1. CONTROLLER (State & Business Logic)
// ────────────────────────────────────────────────
class PersetujuanController extends GetxController {
  final AppController appCtrl = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);

  var isTabBelumDiproses = true.obs;

  /// Mengambil daftar pengajuan yang masih menunggu persetujuan
  Future<List<Map<String, dynamic>>> fetchMenunggu() async {
    try {
      final response = await appCtrl.supabase
          .from('peminjaman')
          .select('*, users!peminjaman_id_peminjam_fkey(nama)')
          .eq('status_transaksi', 'menunggu')
          .order('pengambilan', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch menunggu: $e");
      return [];
    }
  }

  /// Mengambil riwayat semua peminjaman (kecuali menunggu)
  Future<List<Map<String, dynamic>>> fetchRiwayat() async {
    try {
      final response = await appCtrl.supabase
          .from('peminjaman')
          .select('*, users!peminjaman_id_peminjam_fkey(nama)')
          .neq('status_transaksi', 'menunggu')
          .order('pengambilan', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetch riwayat: $e");
      return [];
    }
  }

  /// Update status persetujuan / penolakan
  Future<void> updateStatus({
    required dynamic idPinjam,
    required String status,
    String? alasanPenolakan,
  }) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      final String? idPetugas = appCtrl.userProfile['id_user']?.toString();

      final updateData = <String, dynamic>{
        'status_transaksi': status,
        'id_petugas': idPetugas,
      };

      if (status == 'ditolak' && alasanPenolakan != null && alasanPenolakan.trim().isNotEmpty) {
        updateData['alasan_penolakan'] = alasanPenolakan.trim();
      }

      await appCtrl.supabase.from('peminjaman').update(updateData).eq('id_pinjam', idPinjam);

      Get.back(); // Tutup loading
      Get.back(); // Tutup dialog detail jika terbuka

      isTabBelumDiproses.refresh(); // Trigger rebuild list

      Get.snackbar(
        "Berhasil",
        "Permintaan telah ${status == 'disetujui' ? 'disetujui' : 'ditolak'}",
        backgroundColor: status == 'disetujui' ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar("Error", "Gagal update status: $e", backgroundColor: Colors.red);
    }
  }

  /// Format waktu relatif (contoh: 2 jam lalu, 15 mnt lalu)
  String formatWaktuRelatif(String isoString) {
    try {
      final time = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(time);

      if (diff.inMinutes < 60) return "${diff.inMinutes} mnt lalu";
      if (diff.inHours < 24) return "${diff.inHours} jam lalu";
      return DateFormat('dd MMM yyyy').format(time);
    } catch (_) {
      return isoString;
    }
  }

  /// Format tanggal lengkap untuk detail dialog
  String formatTanggalLengkap(dynamic value) {
    if (value == null) return "-";
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(value.toString()));
    } catch (_) {
      return "-";
    }
  }

  /// Ambil nama peminjam dari data
  String getNamaPeminjam(Map<String, dynamic> item) {
    return item['users']?['nama']?.toString() ?? "Tanpa Nama";
  }

  /// Ambil status display untuk riwayat
  String getStatusDisplay(String status) {
    switch (status) {
      case 'disetujui':
        return "Disetujui";
      case 'ditolak':
        return "Ditolak";
      case 'selesai':
        return "Selesai";
      default:
        return "Unknown";
    }
  }

  /// Ambil warna status untuk riwayat
  Color getStatusColor(String status) {
    switch (status) {
      case 'disetujui':
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ────────────────────────────────────────────────
// 2. PAGE (UI Utama - Stateless)
// ────────────────────────────────────────────────
class PersetujuanPage extends StatelessWidget {
  const PersetujuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PersetujuanController());

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Persetujuan'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Persetujuan",
          style: TextStyle(color: controller.primaryColor, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: controller.primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          _TabSwitch(controller: controller),
          Expanded(
            child: Obx(() => controller.isTabBelumDiproses.value
                ? _ListPengajuanMenunggu(controller: controller)
                : _ListRiwayatPersetujuan(controller: controller)),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────
// 3. WIDGET: Tab Switch (Belum diproses / Riwayat)
// ────────────────────────────────────────────────
class _TabSwitch extends StatelessWidget {
  final PersetujuanController controller;

  const _TabSwitch({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Obx(() => Row(
              children: [
                _TabItem(
                  title: "Belum diproses",
                  active: controller.isTabBelumDiproses.value,
                  onTap: () => controller.isTabBelumDiproses.value = true,
                ),
                _TabItem(
                  title: "Riwayat",
                  active: !controller.isTabBelumDiproses.value,
                  onTap: () => controller.isTabBelumDiproses.value = false,
                ),
              ],
            )),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({required this.title, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F3C58) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// 4. WIDGET: List Pengajuan Menunggu
// ────────────────────────────────────────────────
class _ListPengajuanMenunggu extends StatelessWidget {
  final PersetujuanController controller;

  const _ListPengajuanMenunggu({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.fetchMenunggu(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada pengajuan"));
        }

        final data = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return _PersetujuanCard(
              controller: controller,
              item: item,
              nama: controller.getNamaPeminjam(item),
              desc: "ID Pinjam: ${item['id_pinjam']}",
              waktu: controller.formatWaktuRelatif(item['pengambilan']),
              status: null, // Belum ada status → tombol Detail
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────
// 5. WIDGET: List Riwayat Persetujuan
// ────────────────────────────────────────────────
class _ListRiwayatPersetujuan extends StatelessWidget {
  final PersetujuanController controller;

  const _ListRiwayatPersetujuan({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.fetchRiwayat(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Riwayat kosong"));
        }

        final data = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            final statusStr = item['status_transaksi'];
            final statusDisplay = controller.getStatusDisplay(statusStr);

            return _PersetujuanCard(
              controller: controller,
              item: item,
              nama: controller.getNamaPeminjam(item),
              desc: "ID Pinjam: ${item['id_pinjam']}",
              waktu: controller.formatWaktuRelatif(item['pengambilan']),
              status: statusDisplay,
            );
          },
        );
      },
    );
  }
}

// ────────────────────────────────────────────────
// 6. WIDGET: Card Persetujuan / Riwayat
// ────────────────────────────────────────────────
class _PersetujuanCard extends StatelessWidget {
  final PersetujuanController controller;
  final Map<String, dynamic> item;
  final String nama;
  final String desc;
  final String waktu;
  final String? status;

  const _PersetujuanCard({
    required this.controller,
    required this.item,
    required this.nama,
    required this.desc,
    required this.waktu,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status != null ? controller.getStatusColor(item['status_transaksi']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              if (status == null)
                ElevatedButton(
                  onPressed: () => _showDetailDialog(context, item),
                  style: ElevatedButton.styleFrom(backgroundColor: controller.primaryColor),
                  child: const Text("Detail", style: TextStyle(color: Colors.white, fontSize: 10)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status!,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(waktu, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> item) async {
    Get.dialog(const Center(child: CircularProgressIndicator()));

    try {
      final detailRes = await controller.appCtrl.supabase
          .from('detail_peminjaman')
          .select('jumlah, alat(nama_alat)')
          .eq('id_pinjam', item['id_pinjam']);

      Get.back(); // Tutup loading

      final List details = detailRes as List;

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Detail Peminjaman", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Peminjam: ${controller.getNamaPeminjam(item)}"),
              const SizedBox(height: 10),
              const Text("Barang yang dipinjam:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 5),
              ...details.map((d) => Text("- ${d['alat']['nama_alat']} (${d['jumlah']} unit)")),
              const Divider(),
              Text("Tgl Ambil: ${controller.formatTanggalLengkap(item['pengambilan'])}"),
              Text("Tgl Tenggat: ${controller.formatTanggalLengkap(item['tenggat'])}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _showRejectDialog(item['id_pinjam']),
              child: const Text("Tolak", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => controller.updateStatus(idPinjam: item['id_pinjam'], status: 'disetujui'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Setujui", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar("Error", "Gagal mengambil detail barang");
    }
  }

  void _showRejectDialog(dynamic idPinjam) {
    final TextEditingController alasanCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("Alasan Penolakan"),
        content: TextField(
          controller: alasanCtrl,
          decoration: const InputDecoration(hintText: "Masukkan alasan..."),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (alasanCtrl.text.trim().isNotEmpty) {
                controller.updateStatus(
                  idPinjam: idPinjam,
                  status: 'ditolak',
                  alasanPenolakan: alasanCtrl.text,
                );
              } else {
                Get.snackbar("Peringatan", "Alasan harus diisi", backgroundColor: Colors.orange);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Tolak", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}