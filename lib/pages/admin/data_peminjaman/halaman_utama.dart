import 'package:aplikasi_peminjamanbarang/pages/admin/drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class AdminDataPeminjamanPage extends StatefulWidget {
  const AdminDataPeminjamanPage({super.key});

  @override
  State<AdminDataPeminjamanPage> createState() => _AdminDataPeminjamanPageState();
}

class _AdminDataPeminjamanPageState extends State<AdminDataPeminjamanPage> {
  final c = Get.find<AppController>();
  bool isTabPeminjaman = true;
  final Color primaryColor = const Color(0xFF1F3C58);

  // Mengambil data peminjaman secara Real-time
  Stream<List<Map<String, dynamic>>> _getAdminStream() {
    return c.supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .order('id_pinjam', ascending: false);
  }

  // Fungsi Hapus Data
  Future<void> _hapusData(int id) async {
    try {
      await c.supabase.from('peminjaman').delete().eq('id_pinjam', id);
      
      // Memberikan feedback visual
      Get.snackbar("Terhapus", "Data peminjaman telah dihapus",
          backgroundColor: Colors.black87, colorText: Colors.white);
      
      // Memicu refresh UI setelah hapus
      setState(() {}); 
    } catch (e) {
      Get.snackbar("Gagal", "Error: $e", backgroundColor: Colors.red);
    }
  }

  // Fungsi Refresh Manual
  Future<void> _handleRefresh() async {
    setState(() {});
    return await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(currentPage: 'Data Peminjam'),
      appBar: AppBar(
        title: const Text("Data Peminjam", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F3C58))),
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
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Pencarian . . .",
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1F3C58)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          // 2. Tab Bar
          _buildCustomTabBar(),

          // 3. List Data dengan RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: primaryColor,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getAdminStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        SizedBox(height: Get.height * 0.3),
                        Center(child: Text("Error: ${snapshot.error}")),
                      ],
                    );
                  }

                  final allData = snapshot.data ?? [];
                  
                  final filteredData = isTabPeminjaman 
                      ? allData.where((item) => item['status_transaksi'] != 'selesai').toList()
                      : allData.where((item) => item['status_transaksi'] == 'selesai').toList();

                  if (filteredData.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: Get.height * 0.3),
                        const Center(child: Text("Tidak ada data ditemukan", style: TextStyle(color: Colors.grey))),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(), // Memastikan pull-to-refresh selalu aktif
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) => _buildCardItem(filteredData[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _tabButton("Peminjaman", isTabPeminjaman, () => setState(() => isTabPeminjaman = true)),
          const SizedBox(width: 10),
          _tabButton("Pengembalian", !isTabPeminjaman, () => setState(() => isTabPeminjaman = false)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, 
            style: TextStyle(
              color: active ? Colors.white : Colors.grey, 
              fontWeight: FontWeight.bold,
              fontSize: 13
            )
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> item) {
    String status = (item['status_transaksi'] ?? 'menunggu').toString();
    String idUser = (item['id_peminjam'] ?? '-').toString();
    
    Color statusColor = Colors.orange;
    if (status == 'disetujui') statusColor = Colors.green;
    if (status == 'ditolak') statusColor = Colors.red;
    if (status == 'selesai') statusColor = const Color(0xFF4C6793);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 40, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Peminjam: $idUser", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Text("Pengajuan peminjaman 1 alat", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(15)),
                child: Text(status.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    item['created_at'] != null 
                      ? DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.parse(item['created_at']))
                      : "-", 
                    style: const TextStyle(fontSize: 11, color: Colors.grey)
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _confirmDelete(item['id_pinjam']),
                icon: const Icon(Icons.delete, color: Color(0xFF1F3C58), size: 20),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            ],
          )
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    Get.defaultDialog(
      title: "Hapus Data",
      middleText: "Data akan dihapus permanen dari sistem.",
      textConfirm: "Hapus", confirmTextColor: Colors.white, buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _hapusData(id);
      }
    );
  }
}