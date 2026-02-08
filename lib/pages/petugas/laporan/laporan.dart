import 'package:flutter/material.dart';
import '../drawer.dart'; 

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final Color primaryColor = const Color(0xFF1F3C58);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PetugasDrawer(currentPage: 'Laporan'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Laporan Mingguan",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. RINGKASAN LAPORAN (STATISTIK KECIL)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildSmallStat("Total Pinjam", "24", Colors.blue),
                const SizedBox(width: 10),
                _buildSmallStat("Selesai", "20", Colors.green),
                const SizedBox(width: 10),
                _buildSmallStat("Terlambat", "4", Colors.red),
              ],
            ),
          ),

          const Divider(thickness: 1, indent: 20, endIndent: 20),

          // 2. JUDUL DAFTAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Daftar Peminjaman Minggu Ini",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Icon(Icons.filter_list, color: primaryColor, size: 20),
              ],
            ),
          ),

          // 3. DAFTAR DATA LAPORAN
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildLaporanItem("Aura Monica", "Kamera Canon 600D", "02 Feb - 05 Feb", "Selesai"),
                _buildLaporanItem("Budi Santoso", "Tripod Takara", "03 Feb - 06 Feb", "Selesai"),
                _buildLaporanItem("Siti Aminah", "Lensa Fix 50mm", "05 Feb - 08 Feb", "Dipinjam"),
                _buildLaporanItem("Reza Rahadian", "Lighting Godox", "01 Feb - 04 Feb", "Terlambat"),
              ],
            ),
          ),
        ],
      ),
      
      // 4. TOMBOL CETAK PDF (Visual Only)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Hanya visual, tidak sampai fungsi cetak beneran
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Menyiapkan dokumen PDF...")),
          );
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text("Cetak PDF", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // WIDGET STATISTIK KECIL
  Widget _buildSmallStat(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // WIDGET ITEM LAPORAN (MIRIP HALAMAN SEBELUMNYA)
  Widget _buildLaporanItem(String nama, String alat, String tgl, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(alat, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(tgl, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: status == "Selesai" ? Colors.green : (status == "Terlambat" ? Colors.red : Colors.orange),
            ),
          ),
        ],
      ),
    );
  }
}