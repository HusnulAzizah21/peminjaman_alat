import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class DetailPengembalianPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const DetailPengembalianPage({super.key, required this.data});

  @override
  State<DetailPengembalianPage> createState() => _DetailPengembalianPageState();
}

class _DetailPengembalianPageState extends State<DetailPengembalianPage> {
  final c = Get.find<AppController>();
  DateTime? selectedDate;
  TimeOfDay selectedTime = TimeOfDay.now();
  List listAlat = [];
  int hariTerlambat = 0;
  int estimasiDenda = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetailAlat();
  }

  Future<void> _fetchDetailAlat() async {
    try {
      final res = await c.supabase.from('detail_peminjaman').select('''
        jumlah, alat:id_alat(nama_alat, gambar_url, kategori:id_kategori(nama_kategori))
      ''').eq('id_pinjam', widget.data['id_pinjam']);
      setState(() {
        listAlat = res as List;
        isLoading = false;
      });
    } catch (e) {
      Get.snackbar("Error", "Gagal mengambil detail: $e");
    }
  }

  void _hitungDenda() {
    if (selectedDate == null) return;

    DateTime tenggat = DateTime.parse(widget.data['tenggat']);
    DateTime kembali = DateTime(
      selectedDate!.year, selectedDate!.month, selectedDate!.day, 
      selectedTime.hour, selectedTime.minute
    );

    if (kembali.isAfter(tenggat)) {
      Duration diff = kembali.difference(tenggat);
      int selisih = (diff.inMinutes / 1440).ceil(); 
      setState(() {
        hariTerlambat = selisih;
        estimasiDenda = hariTerlambat * 5000;
      });
    } else {
      setState(() { hariTerlambat = 0; estimasiDenda = 0; });
    }
  }

  Future<void> _simpanPengembalian() async {
    if (selectedDate == null) {
      Get.snackbar("Peringatan", "Silahkan pilih tanggal pengembalian dahulu");
      return;
    }

    try {
      String tglFix = DateTime(
        selectedDate!.year, selectedDate!.month, selectedDate!.day, 
        selectedTime.hour, selectedTime.minute
      ).toIso8601String();
      
      // 1. Update Tabel Peminjaman (Gambar 4)
      await c.supabase.from('peminjaman').update({
        'status_transaksi': 'selesai',
        'pengembalian': tglFix,
      }).eq('id_pinjam', widget.data['id_pinjam']);

      // 2. Insert ke Tabel Denda (Gambar 4)
      if (hariTerlambat > 0) {
        await c.supabase.from('denda').insert({
          'pengembalian': widget.data['id_pinjam'],
          'hari_terlambat': hariTerlambat,
          'tarif_per_hari': 5000,
          // JANGAN kirim nominal_denda karena itu Generated Column (Gambar 5)
        });
      }
      
      Get.back();
      Get.snackbar("Sukses", "Barang telah berhasil dikembalikan", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal memproses: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pengembalian", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back, color: Color(0xFF1F3C58))),
        centerTitle: true,
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Alat (Style Gambar 11)
            ...listAlat.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFB0C4D0).withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, size: 40, color: Color(0xFF1F3C58)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['alat']['nama_alat'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item['alat']['kategori']['nama_kategori'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("${item['jumlah']} unit", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  )
                ],
              ),
            )),

            const SizedBox(height: 15),
            const Divider(),
            _infoBaris("Nama", widget.data['id_peminjam'] ?? "Aura"),
            _infoBaris("Jumlah alat", "${listAlat.length} unit"),
            const SizedBox(height: 10),
            _infoBaris("Pengambilan", _formatTgl(widget.data['pengambilan'])),
            _infoBaris("Tenggat", _formatTgl(widget.data['tenggat'])),

            const SizedBox(height: 20),
            const Text("Pengembalian", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                // Input Tanggal (Gambar 11)
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2027));
                      if (p != null) { setState(() => selectedDate = p); _hitungDenda(); }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(selectedDate == null ? "hh/bb/tttt" : DateFormat('dd MMM yyyy').format(selectedDate!)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Input Jam
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      TimeOfDay? t = await showTimePicker(context: context, initialTime: selectedTime);
                      if (t != null) { setState(() => selectedTime = t); _hitungDenda(); }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(selectedTime.format(context)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            _infoBaris("Terlambat", hariTerlambat > 0 ? "$hariTerlambat Hari" : "-", colorValue: hariTerlambat > 0 ? Colors.red : Colors.black),
            _infoBaris("Nominal denda", "Rp ${NumberFormat('#,###').format(estimasiDenda)}", colorValue: Colors.red),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _simpanPengembalian,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3C58),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Konfirmasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoBaris(String label, String value, {Color colorValue = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: TextStyle(color: colorValue, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatTgl(dynamic d) => d != null ? DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.parse(d.toString())) : "-";
}