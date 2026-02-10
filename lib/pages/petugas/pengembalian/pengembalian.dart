import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/detail_pengembalian.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/detail_riwayat.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart'; 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class PeminjamanAktifPage extends StatefulWidget {
  const PeminjamanAktifPage({super.key});

  @override
  State<PeminjamanAktifPage> createState() => PeminjamanAktifPageState();
}

class PeminjamanAktifPageState extends State<PeminjamanAktifPage> {
  final c = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);

  // Stream data dari tabel peminjaman
  Stream<List<Map<String, dynamic>>> _getPeminjamanStream() {
    return c.supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .order('pengambilan', ascending: false); // Urutkan berdasarkan kolom pengambilan
  }

  // Ambil data relasi Nama User & Jumlah Alat (Manual Join)
  Future<Map<String, dynamic>> _fetchExtraData(String idUser, int idPinjam) async {
    try {
      final user = await c.supabase.from('users').select('nama').eq('id_user', idUser).maybeSingle();
      final items = await c.supabase.from('detail_peminjaman').select('id_detail').eq('id_pinjam', idPinjam);
      
      return {
        'nama': user != null ? user['nama'] : "User tidak ditemukan",
        'total': (items as List).length
      };
    } catch (e) {
      return {'nama': 'Memuat...', 'total': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        // Drawer dipanggil di sini agar bisa muncul
        drawer: PetugasDrawer(currentPage: '',), 
        appBar: AppBar(
          title: const Text("Pengembalian", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: primaryColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: "Peminjaman Aktif"),
              Tab(text: "Selesai"),
            ],
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getPeminjamanStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
            }

            final allData = snapshot.data ?? [];
            
            // Filter status agar tidak case-sensitive (menghindari data kosong karena typo database)
            final aktif = allData.where((e) => 
                e['status_transaksi'].toString().toLowerCase() == 'dipinjam').toList();
            final selesai = allData.where((e) => 
                e['status_transaksi'].toString().toLowerCase() == 'selesai').toList();

            if (allData.isEmpty) {
              return const Center(child: Text("Data transaksi tidak ditemukan"));
            }

            return TabBarView(
              children: [
                _buildList(aktif, isSelesai: false),
                _buildList(selesai, isSelesai: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> data, {required bool isSelesai}) {
    if (data.isEmpty) return Center(child: Text("Tidak ada data ${isSelesai ? 'Selesai' : 'Aktif'}"));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _fetchExtraData(item['id_peminjam'].toString(), item['id_pinjam']),
          builder: (context, res) {
            String nama = res.data?['nama'] ?? "Loading...";
            int total = res.data?['total'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ListTile(
                onTap: () => isSelesai 
                    ? Get.to(() => DetailRiwayatPage(data: item)) 
                    : Get.to(() => DetailPengembalianPage(data: item)),
                leading: Container(
                  width: 5, height: 45,
                  decoration: BoxDecoration(
                    color: primaryColor, 
                    borderRadius: BorderRadius.circular(10)
                  ),
                ),
                title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Peminjaman $total alat", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 12, color: Colors.grey),
                        const SizedBox(width: 5),
                        // KOLOM created_at DIGANTI MENJADI pengambilan
                        Text(
                          "Ambil: ${item['pengambilan'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['pengambilan'])) : '-'}",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => isSelesai 
                      ? Get.to(() => DetailRiwayatPage(data: item)) 
                      : Get.to(() => DetailPengembalianPage(data: item)),
                  child: const Text("Detail", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}