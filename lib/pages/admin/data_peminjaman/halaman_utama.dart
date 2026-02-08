import 'package:flutter/material.dart';
import '../drawer.dart'; // Pastikan import drawer yang benar

class DataPeminjamanAdminPage extends StatefulWidget {
  const DataPeminjamanAdminPage({super.key});

  @override
  State<DataPeminjamanAdminPage> createState() => _DataPeminjamanAdminPageState();
}

class _DataPeminjamanAdminPageState extends State<DataPeminjamanAdminPage> {
  final Color primaryColor = const Color(0xFF1F3C58);
  String selectedTab = "Peminjaman"; 
  TextEditingController searchC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // TAMBAHKAN DRAWER DI SINI
      drawer: const AdminDrawer(currentPage: 'Data Peminjaman'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // PERBAIKI ICON MENU MENGGUNAKAN Builder
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1F3C58)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "Data Peminjam",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: TextField(
                controller: searchC,
                decoration: const InputDecoration(
                  hintText: "Pencarian ...",
                  prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // --- TAB SWITCHER (Peminjaman / Pengembalian) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildTabButton("Peminjaman"),
                const SizedBox(width: 10),
                _buildTabButton("Pengembalian"),
              ],
            ),
          ),

          // --- LIST DATA DINAMIS BERDASARKAN TAB ---
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selectedTab == "Peminjaman" 
                ? _buildPeminjamanList() 
                : _buildPengembalianList(),
            ),
          ),
        ],
      ),
    );
  }

  // Konten List untuk Tab Peminjaman
  Widget _buildPeminjamanList() {
    return ListView(
      key: const ValueKey("PeminjamanList"),
      padding: const EdgeInsets.all(20),
      children: [
        _buildCardItem(
          nama: "Shalsa",
          status: "Ditolak",
          statusColor: Colors.red,
          indicatorColor: Colors.red,
          tanggal: "19/1/2026 - 13:30",
        ),
        _buildCardItem(
          nama: "Alifta",
          status: "Disetujui",
          statusColor: Colors.green,
          indicatorColor: Colors.green,
          tanggal: "17/1/2026 - 10:08",
        ),
      ],
    );
  }

  // Konten List untuk Tab Pengembalian
  Widget _buildPengembalianList() {
    return ListView(
      key: const ValueKey("PengembalianList"),
      padding: const EdgeInsets.all(20),
      children: [
        _buildCardItem(
          nama: "Shalsa",
          status: "Selesai",
          statusColor: const Color(0xFF5D7E97),
          indicatorColor: primaryColor,
          tanggal: "21/1/2026 - 13:30",
        ),
        _buildCardItem(
          nama: "Shalsa",
          status: "Selesai",
          statusColor: const Color(0xFF5D7E97),
          indicatorColor: primaryColor,
          tanggal: "20/1/2026 - 13:30",
        ),
      ],
    );
  }

  // Widget Button Tab yang berubah warna saat ditekan
  Widget _buildTabButton(String label) {
    bool isActive = selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? primaryColor : Colors.blueGrey.shade100),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Card Item Utama
  Widget _buildCardItem({
    required String nama,
    required String status,
    required Color statusColor,
    required Color indicatorColor,
    required String tanggal,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Garis Indikator di Sisi Kiri
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      // Badge Status Berwarna
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    "Pengajuan peminjaman 1 alat",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(tanggal, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      // Icon Tong Sampah
                      const Icon(Icons.delete_outline, size: 20, color: Color(0xFF1F3C58)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}