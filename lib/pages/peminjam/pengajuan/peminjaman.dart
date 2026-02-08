import 'package:aplikasi_peminjamanbarang/pages/peminjam/drawer.dart';
import 'package:flutter/material.dart';

class StatusPeminjamanPage extends StatefulWidget {
  const StatusPeminjamanPage({super.key});

  @override
  State<StatusPeminjamanPage> createState() => _StatusPeminjamanPageState();
}

class _StatusPeminjamanPageState extends State<StatusPeminjamanPage> {
  bool isTabPengajuan = true; // State untuk navigasi tab

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1F3C58);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PeminjamDrawer(currentPage: 'Peminjaman'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Peminjaman", 
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          // CUSTOM TAB BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabItem("Pengajuan", isTabPengajuan, () {
                    setState(() => isTabPengajuan = true);
                  }),
                  _buildTabItem("Pinjaman saya", !isTabPengajuan, () {
                    setState(() => isTabPengajuan = false);
                  }),
                ],
              ),
            ),
          ),

          // ISI KONTEN (UI ONLY)
          Expanded(
            child: isTabPengajuan 
              ? _buildUIListPengajuan(primaryColor) 
              : _buildUIListPinjamanSaya(),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TAB ITEM ---
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
            ),
          ),
        ),
      ),
    );
  }

  // --- UI TAB 1: PENGAJUAN (DUMMY) ---
  Widget _buildUIListPengajuan(Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _cardPengajuan("Menunggu", primaryColor, "Monica", "10 mnt yg lalu"),
        _cardPengajuan("Ditolak", Colors.red, "Monica", "2 jam yg lalu"),
        _cardPengajuan("Disetujui", Colors.green, "Monica", "Kemarin"),
      ],
    );
  }

  Widget _cardPengajuan(String status, Color color, String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pengajuan peminjaman", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(width: 4, height: 40, color: color),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Pengajuan peminjaman 1 alat", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI TAB 2: PINJAMAN SAYA (DUMMY DENGAN DROPDOWN) ---
  Widget _buildUIListPinjamanSaya() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _cardPinjamanAktif("Sony Alpha A7", "08/02/2026 - 10:00", "10/02/2026 - 17:00"),
        _cardPinjamanAktif("Tripod Takara", "07/02/2026 - 09:00", "09/02/2026 - 17:00"),
      ],
    );
  }

  Widget _cardPinjamanAktif(String alat, String tglAmbil, String tglBalik) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade400, width: 1.5),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          title: const Text("Pinjaman Aktif", 
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dateBox("Pengambilan", tglAmbil),
                Container(width: 1, height: 25, color: Colors.grey.shade300),
                _dateBox("Tenggat", tglBalik),
              ],
            ),
          ),
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.grey),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text("Elektronik", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Text("1 unit", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateBox(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}