import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/app_controller.dart'; 
import '../drawer.dart';
// Pastikan path detail_pengembalian ini benar
import 'detail_pengembalian.dart'; 

// =========================================================
// 1. MODEL
// =========================================================
class PeminjamanModel {
  final int idPinjam;
  final String idPeminjam;
  final DateTime? pengambilan;
  final DateTime? tenggat;
  final String status;

  PeminjamanModel({
    required this.idPinjam,
    required this.idPeminjam,
    this.pengambilan,
    this.tenggat,
    required this.status,
  });

  factory PeminjamanModel.fromMap(Map<String, dynamic> map) {
    return PeminjamanModel(
      // Menggunakan tryParse untuk menghindari TypeError null
      idPinjam: int.tryParse(map['id_pinjam']?.toString() ?? '0') ?? 0,
      idPeminjam: map['id_peminjam']?.toString() ?? '',
      pengambilan: map['pengambilan'] != null ? DateTime.tryParse(map['pengambilan']) : null,
      tenggat: map['tenggat'] != null ? DateTime.tryParse(map['tenggat']) : null,
      status: map['status_transaksi']?.toString() ?? 'aktif',
    );
  }
}

// =========================================================
// 2. CONTROLLER
// =========================================================
class PetugasPengembalianController extends GetxController {
  final SupabaseClient supabase = Get.find<AppController>().supabase;
  
  var isTabAktif = true.obs;
  var searchQuery = ''.obs;

  Future<Map<String, dynamic>> getCardDetails(PeminjamanModel p) async {
    try {
      final userRes = await supabase
          .from('users')
          .select('nama')
          .eq('id_user', p.idPeminjam)
          .maybeSingle();

      final detailRes = await supabase
          .from('detail_peminjaman')
          .select('jumlah')
          .eq('id_pinjam', p.idPinjam);

      int totalAlat = 0;
      if (detailRes != null) {
        for (var item in (detailRes as List)) {
          // Menghindari TypeError dengan default value 0
          totalAlat += int.tryParse(item['jumlah']?.toString() ?? '0') ?? 0;
        }
      }

      return {
        'nama': userRes?['nama'] ?? 'User Tidak Dikenal',
        'jumlah': totalAlat,
      };
    } catch (e) {
      return {'nama': 'Error', 'jumlah': 0};
    }
  }
}

// =========================================================
// 3. VIEW
// =========================================================
class PetugasPengembalianPage extends StatelessWidget {
  PetugasPengembalianPage({super.key});

  final PetugasPengembalianController controller = Get.put(PetugasPengembalianController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Pengembalian'),
      appBar: AppBar(
        title: const Text("Pengembalian", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F3C58)),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabSwitch(),
          const SizedBox(height: 10),
          _buildDataList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        decoration: InputDecoration(
          hintText: "Cari data...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tabButton("Aktif (Disetujui)", controller.isTabAktif.value, () => controller.isTabAktif.value = true),
          const SizedBox(width: 12),
          _tabButton("Selesai", !controller.isTabAktif.value, () => controller.isTabAktif.value = false),
        ],
      ),
    ));
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F3C58) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: active ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(label, textAlign: TextAlign.center, 
            style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDataList() {
  return Expanded(
    child: StreamBuilder<List<Map<String, dynamic>>>(
      stream: controller.supabase
          .from('peminjaman')
          .stream(primaryKey: ['id_pinjam'])
          .order('id_pinjam', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Tidak ada data peminjaman"));
        }

        final listPeminjaman = snapshot.data!
            .map((m) => PeminjamanModel.fromMap(m))
            .toList();

        // ──── Bagian ini dipindah ke Obx terpisah ────
        return Obx(() {
          final filteredData = listPeminjaman.where((p) {
            if (controller.isTabAktif.value) {
              return p.status == 'disetujui';
            } else {
              return p.status == 'selesai';
            }
          }).toList();

          if (filteredData.isEmpty) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: filteredData.length,
            itemBuilder: (context, index) => _buildCardItem(filteredData[index]),
          );
        });
      },
    ),
  );
}

  Widget _buildCardItem(PeminjamanModel peminjaman) {
    return FutureBuilder<Map<String, dynamic>>(
      future: controller.getCardDetails(peminjaman),
      builder: (context, snapshot) {
        final detail = snapshot.data ?? {'nama': 'Memuat...', 'jumlah': 0};
        
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1F3C58).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF1F3C58)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      "${detail['jumlah']} Alat • ${peminjaman.pengambilan != null ? DateFormat('dd MMM yyyy').format(peminjaman.pengambilan!) : '-'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Tombol hanya muncul jika tab Aktif (untuk memproses pengembalian)
              if (controller.isTabAktif.value)
              ElevatedButton(
                onPressed: () => Get.to(() => DetailPengembalianAktifPage(rawData: {
                  'id_pinjam': peminjaman.idPinjam,
                  'id_peminjam': peminjaman.idPeminjam,
                  'tenggat': peminjaman.tenggat?.toIso8601String(),
                })),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F3C58)),
                child: const Text("Detail", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}