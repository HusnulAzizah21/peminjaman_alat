import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class DetailRiwayatPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const DetailRiwayatPage({super.key, required this.data});

  @override
  State<DetailRiwayatPage> createState() => _DetailRiwayatPageState();
}

class _DetailRiwayatPageState extends State<DetailRiwayatPage> {
  final c = Get.find<AppController>();
  Map<String, dynamic>? dendaInfo;
  List detailAlat = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSemuaDetail();
  }

  Future<void> _loadSemuaDetail() async {
    try {
      // 1. Ambil Detail Alat & Join ke Kategori (Relasi Gambar 2)
      final resAlat = await c.supabase.from('detail_peminjaman').select('''
        jumlah, 
        alat:id_alat(
          nama_alat, 
          gambar_url,
          kategori:id_kategori(nama_kategori)
        )
      ''').eq('id_pinjam', widget.data['id_pinjam']);

      // 2. Ambil Info Denda (Relasi Gambar 2 & 4)
      final resDenda = await c.supabase.from('denda')
          .select()
          .eq('pengembalian', widget.data['id_pinjam'])
          .maybeSingle();

      setState(() {
        detailAlat = resAlat as List;
        dendaInfo = resDenda;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Load Detail: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Riwayat", 
          style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, 
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F3C58)), 
          onPressed: () => Get.back()
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- DAFTAR ALAT (Style Gambar 6 & 12) ---
                  const SizedBox(height: 10),
                  ...detailAlat.map((item) => _buildHeaderCard(item)).toList(),
                  
                  const SizedBox(height: 25),
                  const Divider(thickness: 1),
                  
                  // --- INFORMASI PEMINJAM ---
                  _rowDetail("Nama", widget.data['users']?['nama'] ?? "Monica"),
                  _rowDetail("Jumlah alat", "${detailAlat.length} unit"),
                  
                  const Divider(thickness: 1),
                  
                  // --- INFORMASI WAKTU ---
                  _rowDetail("Pengambilan", _formatFull(widget.data['pengambilan'])),
                  _rowDetail("Tenggat", _formatFull(widget.data['tenggat'])),
                  _rowDetail("Pengembalian", _formatFull(widget.data['pengembalian'])),
                  
                  const Divider(thickness: 1),
                  
                  // --- INFORMASI DENDA (Gambar 3 & 12) ---
                  _rowDetail("Terlambat", dendaInfo != null ? "${dendaInfo!['hari_terlambat']} Hari" : "-"),
                  _rowDetail(
                    "Total denda", 
                    dendaInfo != null 
                        ? "Rp ${NumberFormat('#,###').format(dendaInfo!['nominal_denda'])}" 
                        : "Rp -"
                  ),
                  
                  const Divider(thickness: 1),
                  const SizedBox(height: 15),
                  
                  // --- STATUS AKHIR (Style Gambar 6) ---
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF1F3C58), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Selesai", 
                        style: TextStyle(
                          color: const Color(0xFF1F3C58), 
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // Widget untuk Card Alat (Biru Keabuan sesuai Mockup)
  Widget _buildHeaderCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB0C4D0).withOpacity(0.5), // Warna Gambar 6/12
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Gambar Alat
          Container(
            width: 65, height: 65,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12),
              image: item['alat']['gambar_url'] != null 
                ? DecorationImage(image: NetworkImage(item['alat']['gambar_url']), fit: BoxFit.cover)
                : null,
            ),
            child: item['alat']['gambar_url'] == null 
                ? const Icon(Icons.camera_alt, color: Colors.grey, size: 30) 
                : null,
          ),
          const SizedBox(width: 18),
          // Info Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['alat']['nama_alat'] ?? "Alat", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F3C58))
                ),
                Text(
                  item['alat']['kategori']?['nama_kategori'] ?? "Kategori", 
                  style: const TextStyle(fontSize: 12, color: Colors.black54)
                ),
                const SizedBox(height: 4),
                Text(
                  "${item['jumlah']} unit", 
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1F3C58))
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget Baris Detail
  Widget _rowDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }

  // Formatter Tanggal (dd/M/yyyy - HH:mm sesuai Mockup)
  String _formatFull(dynamic d) {
    if (d == null) return "-";
    return DateFormat('dd/M/yyyy - HH:mm').format(DateTime.parse(d.toString()).toLocal());
  }
}