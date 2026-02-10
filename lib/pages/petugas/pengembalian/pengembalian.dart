import 'package:aplikasi_peminjamanbarang/pages/petugas/drawer.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/pengembalian/detail_pengembalian.dart';
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
  // 1. Inisialisasi controller dengan 'late' untuk menjamin keamanan saat build
  late final AppController c;
  bool isTabAktif = true;

  // Variabel pendukung perhitungan denda
  int hariTerlambat = 0;
  int nominalDenda = 0;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 2. Memastikan AppController ditemukan sebelum widget dirender
    try {
      c = Get.find<AppController>();
    } catch (e) {
      debugPrint("Error: AppController tidak ditemukan di memori GetX");
    }
  }

  /// FUNGSI: Mengambil Nama User dari tabel 'users' berdasarkan UUID
  /// Dilengkapi pengecekan null untuk mencegah error 'null is not a subtype of String'
  Future<String> _getNamaPeminjam(String? userId) async {
    if (userId == null) return "User Tidak Terdeteksi";
    try {
      final res = await c.supabase
          .from('users')
          .select('nama')
          .eq('id_user', userId)
          .maybeSingle();
      
      // Jika data ada, ambil 'nama', jika tidak ada gunakan fallback "Tanpa Nama"
      return res != null ? (res['nama']?.toString() ?? "Tanpa Nama") : "User Tidak Ditemukan";
    } catch (e) {
      return "Gagal Memuat";
    }
  }

  /// FUNGSI: Menghitung total jumlah alat dari tabel 'detail_peminjaman' secara dinamis
  Future<int> _getTotalAlat(int? idPinjam) async {
    if (idPinjam == null) return 0;
    try {
      final res = await c.supabase
          .from('detail_peminjaman')
          .select('jumlah')
          .eq('id_pinjam', idPinjam);
      
      int total = 0;
      if (res != null) {
        for (var row in res) {
          // Casting aman ke int, jika null dianggap 0
          total += (row['jumlah'] as int? ?? 0);
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// FUNGSI: Logika perhitungan denda otomatis
  void hitungSelisihDanDenda(Map<String, dynamic> itemData) {
    if (itemData['tenggat'] == null) return;

    DateTime tenggat = DateTime.parse(itemData['tenggat']);
    DateTime tglKembali = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime tglTenggatSaja = DateTime(tenggat.year, tenggat.month, tenggat.day);

    if (tglKembali.isAfter(tglTenggatSaja)) {
      int selisih = tglKembali.difference(tglTenggatSaja).inDays;
      if (selisih == 0) selisih = 1; 
      
      setState(() {
        hariTerlambat = selisih;
        nominalDenda = selisih * 5000;
      });
    } else {
      setState(() {
        hariTerlambat = 0;
        nominalDenda = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Pengembalian'), 
      appBar: AppBar(
        title: const Text("Pengembalian", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
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
          // KOMPONEN: Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pencarian . . .",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25), 
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // KOMPONEN: Tab Bar (Aktif | Selesai)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _tabBtn("Peminjaman Aktif", isTabAktif, () => setState(() => isTabAktif = true)),
                const SizedBox(width: 10),
                _tabBtn("Selesai", !isTabAktif, () => setState(() => isTabAktif = false)),
              ],
            ),
          ),

          // LIST DATA: StreamBuilder untuk memantau perubahan data secara langsung
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('peminjaman')
                  .stream(primaryKey: ['id_pinjam'])
                  .order('id_pinjam', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Gagal mengambil data dari server"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Menangani data null dengan fallback list kosong
                final allData = snapshot.data ?? [];
                
                final listData = isTabAktif 
                    ? allData.where((e) => e['status_transaksi'] != 'selesai').toList()
                    : allData.where((e) => e['status_transaksi'] == 'selesai').toList();

                if (listData.isEmpty) return const Center(child: Text("Tidak ada data peminjaman"));

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: listData.length,
                  itemBuilder: (context, index) => _itemCard(listData[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F3C58) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: active ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(label, 
              style: TextStyle(
                  color: active ? Colors.white : Colors.grey, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12)),
        ),
      ),
    );
  }

  /// WIDGET: Kartu Item (Mendukung Join Tabel secara manual)
  Widget _itemCard(Map<String, dynamic> item) {
    // Menyiapkan ID secara aman sebelum diproses FutureBuilder
    final String? idUser = item['id_peminjam']?.toString();
    final int? idPinjam = item['id_pinjam'] as int?;

    return FutureBuilder(
      future: Future.wait([
        _getNamaPeminjam(idUser),
        _getTotalAlat(idPinjam),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> subSnapshot) {
        // Fallback saat data sedang loading di dalam kartu
        String nama = subSnapshot.hasData ? subSnapshot.data![0] : "Memuat nama...";
        int jumlah = subSnapshot.hasData ? subSnapshot.data![1] : 0;
        
        String tanggal = "-";
        if (item['pengambilan'] != null) {
          try {
            tanggal = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['pengambilan']));
          } catch (e) {
            tanggal = "Format Tgl Error";
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis // MENCEGAH: Right Overflow
                    ),
                    Text("Peminjaman $jumlah alat", 
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(tanggal, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3C58), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: () {
                  hitungSelisihDanDenda(item);
                  Get.to(() => DetailPengembalianPage(data: item));
                },
                child: const Text("Detail", style: TextStyle(fontSize: 12, color: Colors.white)),
              )
            ],
          ),
        );
      }
    );
  }
}