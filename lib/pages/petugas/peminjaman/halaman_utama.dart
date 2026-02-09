import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../drawer.dart'; 

class PersetujuanPage extends StatefulWidget {
  const PersetujuanPage({super.key});

  @override
  State<PersetujuanPage> createState() => _PersetujuanPageState();
}

class _PersetujuanPageState extends State<PersetujuanPage> {
  bool isTabBelumDiproses = true;
  final Color primaryColor = const Color(0xFF1F3C58);
  final c = Get.find<AppController>();

  // ================= FETCH DATA (MENUNGGU) =================
  Future<List<Map<String, dynamic>>> _getMenunggu() async {
    try {
      final response = await c.supabase
          .from('peminjaman')
          .select('*, users!peminjaman_id_peminjam_fkey(nama)')
          .eq('status_transaksi', 'menunggu')
          .order('pengambilan', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Fetch Menunggu: $e");
      return [];
    }
  }

  // ================= FETCH DATA (RIWAYAT) =================
  Future<List<Map<String, dynamic>>> _getRiwayat() async {
    try {
      final response = await c.supabase
          .from('peminjaman')
          .select('*, users!peminjaman_id_peminjam_fkey(nama)')
          .neq('status_transaksi', 'menunggu')
          .order('pengambilan', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Fetch Riwayat: $e");
      return [];
    }
  }

  // ================= UPDATE STATUS (DIPERBAIKI) =================
  Future<void> _updateStatus(dynamic idPinjam, String status, {String? alasan}) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      // PERBAIKAN DI SINI: Menggunakan userProfile['id_user'] sesuai AppController kamu
      final String? idPetugas = c.userProfile['id_user']?.toString();

      Map<String, dynamic> updateData = {
        'status_transaksi': status,
        'id_petugas': idPetugas, 
      };

      if (status == 'ditolak' && alasan != null) {
        updateData['alasan_penolakan'] = alasan;
      }

      await c.supabase.from('peminjaman').update(updateData).eq('id_pinjam', idPinjam);

      // Menutup semua dialog (loading & detail)
      if (Get.isDialogOpen!) Get.back(); 
      if (Get.isDialogOpen!) Get.back(); 
      
      setState(() {}); // Refresh list
      
      Get.snackbar("Berhasil", "Permintaan telah $status",
          backgroundColor: status == 'disetujui' ? Colors.green : Colors.red, 
          colorText: Colors.white);
    } catch (e) {
      if (Get.isDialogOpen!) Get.back(); // Tutup loading jika error
      Get.snackbar("Error", "Gagal update status: $e", backgroundColor: Colors.red);
    }
  }

  // Fungsi pembantu untuk memunculkan input alasan saat menolak
  void _showRejectDialog(dynamic idPinjam) {
    final TextEditingController alasanController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Alasan Penolakan"),
        content: TextField(
          controller: alasanController,
          decoration: const InputDecoration(hintText: "Masukkan alasan..."),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (alasanController.text.isNotEmpty) {
                _updateStatus(idPinjam, 'ditolak', alasan: alasanController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Persetujuan'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Persetujuan",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: isTabBelumDiproses
                ? _buildList(isRiwayat: false)
                : _buildList(isRiwayat: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            _tabItem("Belum diproses", isTabBelumDiproses, () => setState(() => isTabBelumDiproses = true)),
            _tabItem("Riwayat", !isTabBelumDiproses, () => setState(() => isTabBelumDiproses = false)),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(String title, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(title,
              style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildList({required bool isRiwayat}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: isRiwayat ? _getRiwayat() : _getMenunggu(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(isRiwayat ? "Riwayat kosong" : "Tidak ada pengajuan"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, i) {
            final item = snapshot.data![i];
            final String nama = item['users']?['nama'] ?? 'Tanpa Nama';
            final String statusStr = item['status_transaksi'];

            return _cardPersetujuan(
              nama,
              "ID Pinjam: ${item['id_pinjam']}",
              _formatWaktu(item['pengambilan']),
              isRiwayat ? (statusStr == 'disetujui' ? "Disetujui" : (statusStr == 'ditolak' ? "Ditolak" : "Selesai")) : null,
              item,
            );
          },
        );
      },
    );
  }

  Widget _cardPersetujuan(String nama, String desc, String waktu, String? status, Map<String, dynamic> item) {
    Color statusColor = Colors.grey;
    if(status == "Disetujui" || status == "Selesai") statusColor = Colors.green;
    if(status == "Ditolak") statusColor = Colors.red;

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
              status == null
                  ? ElevatedButton(
                      onPressed: () => _showDetailDialog(item),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: const Text("Detail", style: TextStyle(color: Colors.white, fontSize: 10)),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _showDetailDialog(Map<String, dynamic> item) async {
    Get.dialog(const Center(child: CircularProgressIndicator()));

    try {
      final detailRes = await c.supabase
          .from('detail_peminjaman')
          .select('jumlah, alat(nama_alat)')
          .eq('id_pinjam', item['id_pinjam']);
      
      if (Get.isDialogOpen!) Get.back(); // Tutup loading

      final List details = detailRes as List;

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Detail Peminjaman", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Peminjam: ${item['users']?['nama']}"),
              const SizedBox(height: 10),
              const Text("Barang yang dipinjam:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 5),
              ...details.map((d) => Text("- ${d['alat']['nama_alat']} (${d['jumlah']} unit)")).toList(),
              const Divider(),
              Text("Tgl Ambil: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['pengambilan']))}"),
              Text("Tgl Tenggat: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['tenggat']))}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _showRejectDialog(item['id_pinjam']), 
              child: const Text("Tolak", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => _updateStatus(item['id_pinjam'], 'disetujui'), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Setujui", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar("Error", "Gagal mengambil detail barang");
    }
  }

  String _formatWaktu(String iso) {
    try {
      final time = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(time);
      if (diff.inMinutes < 60) return "${diff.inMinutes} mnt lalu";
      if (diff.inHours < 24) return "${diff.inHours} jam lalu";
      return DateFormat('dd MMM yyyy').format(time);
    } catch (e) {
      return iso;
    }
  }
}