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
  final c = Get.find<AppController>();
  bool isTabAktif = true;

  // Variabel tambahan untuk mendukung fungsi hitungSelisihDanDenda
  int hariTerlambat = 0;
  int nominalDenda = 0;
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic> data = {}; // Akan diisi saat memilih item jika diperlukan secara global

  // ================= LOGIKA HITUNG DENDA =================
  void hitungSelisihDanDenda(Map<String, dynamic> itemData) {
    if (itemData['tenggat'] == null) return;

    DateTime tenggat = DateTime.parse(itemData['tenggat']);
    // Menghilangkan komponen waktu agar perhitungan selisih hari akurat
    DateTime tglKembali = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime tglTenggatSaja = DateTime(tenggat.year, tenggat.month, tenggat.day);

    if (tglKembali.isAfter(tglTenggatSaja)) {
      int selisih = tglKembali.difference(tglTenggatSaja).inDays;
      
      // Jika lewat jam di hari yang sama namun secara tanggal sudah lewat, minimal 1 hari
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
  // Drawer sudah terpasang di sini
  drawer: const PetugasDrawer(currentPage: 'Pengembalian'), 
  appBar: AppBar(
    title: const Text("Pengembalian", 
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
    centerTitle: true,
    backgroundColor: Colors.white,
    elevation: 0,
    // PERBAIKAN: Gunakan Builder agar IconButton bisa mengakses ScaffoldState untuk membuka drawer
    leading: Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1F3C58)),
          onPressed: () {
            Scaffold.of(context).openDrawer(); // Ini fungsi untuk membuka drawer
          },
        );
      },
    ),
  ),
      body: Column(
        children: [
          // Search Bar
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
          
          // Tab Bar Custom (Peminjaman Aktif | Selesai)
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

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('peminjaman')
                  .stream(primaryKey: ['id_pinjam'])
                  .order('id_pinjam', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data"));
                }
                
                final listData = isTabAktif 
                    ? snapshot.data!.where((e) => e['status_transaksi'] != 'selesai').toList()
                    : snapshot.data!.where((e) => e['status_transaksi'] == 'selesai').toList();

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

  Widget _itemCard(Map<String, dynamic> item) {
    String namaPeminjam = item['id_peminjam']?.toString() ?? "Tanpa Nama";
    String tanggal = "-";
    if (item['created_at'] != null) {
      tanggal = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['created_at']));
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(namaPeminjam, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Peminjaman ${item['jumlah_alat'] ?? 0} alat", 
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F3C58), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              // Menjalankan kalkulasi denda sebelum pindah halaman (opsional)
              hitungSelisihDanDenda(item);
              Get.to(() => DetailPengembalianPage(data: item));
            },
            child: const Text("Detail", style: TextStyle(fontSize: 12, color: Colors.white)),
          )
        ],
      ),
    );
  }
}