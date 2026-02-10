import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/detail_pengembalian.dart'; // sesuaikan path
import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/riwayat.dart'; // jika ada
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class PetugasPengembalianPage extends StatefulWidget {
  const PetugasPengembalianPage({super.key});

  @override
  State<PetugasPengembalianPage> createState() => _PetugasPengembalianPageState();
}

class _PetugasPengembalianPageState extends State<PetugasPengembalianPage> {
  final c = Get.find<AppController>();
  bool isTabAktif = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Pengembalian'),
      appBar: AppBar(
        title: const Text(
          "Pengembalian",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58)),
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
      body: Column(
        children: [
          // Search bar (belum fungsional)
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pencarian...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTabButton("Peminjaman Aktif", isTabAktif, () => setState(() => isTabAktif = true)),
                const SizedBox(width: 12),
                _buildTabButton("Selesai", !isTabAktif, () => setState(() => isTabAktif = false)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase
                  .from('peminjaman')
                  .stream(primaryKey: ['id_pinjam'])
                  .order('pengambilan', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada data peminjaman"));
                }

                final allData = snapshot.data!;

                final filteredData = isTabAktif
                    ? allData.where((e) => e['status_transaksi'] != 'selesai').toList()
                    : allData.where((e) => e['status_transaksi'] == 'selesai').toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final item = filteredData[index];
                    return _buildItemCard(item, isTabAktif);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F3C58) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: active ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool isAktif) {
    final idPinjam    = item['id_pinjam']    as int?;     // int4
    final idPeminjam  = item['id_peminjam']  as String?;  // uuid
    final pengambilan = item['pengambilan']  as String?;
    final tenggat     = item['tenggat']      as String?;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getNamaDanJumlah(idPeminjam, idPinjam),
      builder: (context, snapshot) {
        // Hilangkan loading indicator sepenuhnya
        // Langsung tampilkan card, tapi isi data tergantung snapshot
        final data = snapshot.hasData ? snapshot.data ?? {} : {};
        final nama = data['nama'] as String? ?? 'Memuat nama...';
        final jumlahAlat = data['jumlah'] as int? ?? 0;

        String subtitleDate = '-';
        if (isAktif) {
          if (pengambilan != null && pengambilan.isNotEmpty) {
            try {
              subtitleDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(pengambilan));
            } catch (_) {
              subtitleDate = pengambilan;
            }
          }
        } else {
          if (pengambilan != null && tenggat != null && pengambilan.isNotEmpty && tenggat.isNotEmpty) {
            try {
              final tglAmbil = DateFormat('dd/MM/yyyy').format(DateTime.parse(pengambilan));
              final tglTenggat = DateFormat('dd/MM/yyyy').format(DateTime.parse(tenggat));
              subtitleDate = "$tglAmbil - $tglTenggat";
            } catch (_) {
              subtitleDate = '$pengambilan - $tenggat';
            }
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1F3C58),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Peminjaman $jumlahAlat alat",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          subtitleDate,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (isAktif) {
                    Get.to(() => DetailPengembalianAktifPage(rawData: item,));
                  } else {
                    Get.to(() => DetailPengembalianSelesaiPage(data: item));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3C58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  "Detail",
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
//stop
  Future<Map<String, dynamic>> _getNamaDanJumlah(String? idPeminjam, int? idPinjam) async {
    String nama = 'Peminjam tidak ditemukan';
    int jumlahAlat = 0;

    try {
      // Ambil nama peminjam (uuid → String)
      if (idPeminjam != null && idPeminjam.isNotEmpty) {
        final userRes = await c.supabase
            .from('users')
            .select('nama')
            .eq('id_user', idPeminjam)
            .maybeSingle();

        nama = userRes?['nama'] as String? ?? 'Peminjam tidak ditemukan';
      }

      // Hitung jumlah alat (id_pinjam → int)
      if (idPinjam != null) {
        final detailRes = await c.supabase
            .from('detail_peminjaman')
            .select('jumlah')
            .eq('id_pinjam', idPinjam);

        jumlahAlat = detailRes.fold<int>(
          0,
          (sum, e) => sum + (e['jumlah'] as int? ?? 0),
        );
      }
    } catch (e, stack) {
      debugPrint("Error fetch data card: $e");
      debugPrint("Stack trace: $stack");
      nama = 'Error memuat nama';
    }

    return {'nama': nama, 'jumlah': jumlahAlat};
  }
}