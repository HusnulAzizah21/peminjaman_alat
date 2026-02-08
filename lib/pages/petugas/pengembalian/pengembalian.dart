import 'package:flutter/material.dart';
import '../drawer.dart'; // Pastikan path file drawer petugas sudah benar

class PengembalianPetugasPage extends StatefulWidget {
  const PengembalianPetugasPage({super.key});

  @override
  State<PengembalianPetugasPage> createState() => _PengembalianPetugasPageState();
}

class _PengembalianPetugasPageState extends State<PengembalianPetugasPage> {
  bool isTabAktif = true; 
  final Color primaryColor = const Color(0xFF1F3C58);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Drawer dipanggil agar menu samping bisa diakses
      drawer: const PetugasDrawer(currentPage: 'Pengembalian'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Pengembalian",
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
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pencarian . . .",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
              ),
            ), // Kurung penutup TextField yang benar
          ),

          // 2. TAB SWITCHER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabItem("Peminjaman Aktif", isTabAktif, () {
                    setState(() => isTabAktif = true);
                  }),
                  _buildTabItem("Selesai", !isTabAktif, () {
                    setState(() => isTabAktif = false);
                  }),
                ],
              ),
            ),
          ),

          // 3. DAFTAR KONTEN BERDASARKAN TAB
          Expanded(
            child: isTabAktif 
                ? _buildListPeminjamanAktif() 
                : _buildListSelesai(),
          ),
        ],
      ),
    );
  }

  // WIDGET UNTUK ITEM TAB
  Widget _buildTabItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1F3C58) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: DAFTAR PEMINJAMAN AKTIF
  Widget _buildListPeminjamanAktif() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPengembalianCard("Aura", "Peminjaman 1 alat", "21/1/2026 - 08:30"),
      ],
    );
  }

  // TAB 2: DAFTAR SELESAI
  Widget _buildListSelesai() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPengembalianCard("Aura", "Peminjaman 2 alat", "16/1/2026 | 13:30 - 21/1/2026 | 13:30"),
        _buildPengembalianCard("Kania", "Peminjaman 2 alat", "11/1/2026 | 13:30 - 15/1/2026 | 13:30"),
        _buildPengembalianCard("Shalsa", "Peminjaman 3 alat", "12/1/2026 | 13:30 - 15/1/2026 | 13:30"),
      ],
    );
  }

  // WIDGET KARTU ITEM
  Widget _buildPengembalianCard(String nama, String deskripsi, String waktu) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 35,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        deskripsi,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  minimumSize: const Size(60, 30),
                  elevation: 0,
                ),
                child: const Text(
                  "Detail",
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                waktu,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
} // Penutup class yang tadi hilang