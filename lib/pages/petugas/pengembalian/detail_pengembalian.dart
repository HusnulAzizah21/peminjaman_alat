import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class DetailPengembalianPage extends StatefulWidget {
  final Map<String, dynamic> data; // Data dari halaman daftar petugas
  const DetailPengembalianPage({super.key, required this.data});

  @override
  State<DetailPengembalianPage> createState() => _DetailPengembalianPageState();
}

class _DetailPengembalianPageState extends State<DetailPengembalianPage> {
  final c = Get.find<AppController>();
  
  // State untuk input dan hasil hitungan
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List listAlat = [];
  int hariTerlambat = 0;
  int denda = 0;
  bool isLoading = true;
  bool isSuccess = false;

  @override
  void initState() {
    super.initState();
    _fetchDetailAlat(); // Ambil daftar alat yang dipinjam
    _hitungDendaOtomatis(); // Hitung denda awal
  }

  // Ambil data alat dari tabel detail_peminjaman
  Future<void> _fetchDetailAlat() async {
    try {
      final res = await c.supabase
          .from('detail_peminjaman')
          .select('jumlah, alat(nama_alat, id_kategori)')
          .eq('id_pinjam', widget.data['id_pinjam']);
      setState(() {
        listAlat = res;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // Logika: (selisih hari = tanggal pengembalian - tenggat) dan (denda = selisih x 5000)
  void _hitungDendaOtomatis() {
    if (widget.data['tenggat'] == null) return;

    DateTime tenggat = DateTime.parse(widget.data['tenggat']);
    DateTime tglKembali = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute
    );

    if (tglKembali.isAfter(tenggat)) {
      // Hitung selisih hari
      int selisih = tglKembali.difference(tenggat).inDays;
      
      // Jika di hari yang sama tapi lewat jam, hitung minimal 1 hari sesuai logika denda
      if (tglKembali.day != tenggat.day && selisih == 0) selisih = 1;
      if (selisih < 0) selisih = 0;

      setState(() {
        hariTerlambat = selisih;
        denda = hariTerlambat * 5000; // Selisih hari x 5000
      });
    } else {
      setState(() {
        hariTerlambat = 0;
        denda = 0;
      });
    }
  }

  Future<void> _konfirmasiPengembalian() async {
    try {
      // Update status ke 'selesai' agar pindah ke riwayat
      // Database Trigger fn_kembalikan_stok_otomatis akan otomatis menambah stok alat
      await c.supabase.from('peminjaman').update({
        'status_transaksi': 'selesai',
        'pengembalian': DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day,
          selectedTime.hour, selectedTime.minute
        ).toIso8601String(),
      }).eq('id_pinjam', widget.data['id_pinjam']);

      setState(() => isSuccess = true);
      Get.snackbar("Berhasil", "Data dipindahkan ke riwayat", 
          backgroundColor: Colors.white, colorText: Colors.green);
      
      Future.delayed(const Duration(seconds: 2), () => Get.back());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pengembalian", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
        centerTitle: true, elevation: 0, backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1F3C58)), onPressed: () => Get.back()),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            // List Barang sesuai gambar
            ...listAlat.map((item) => _cardAlat(item)).toList(),
            const Divider(height: 30),
            _rowInfo("Nama", widget.data['id_peminjam']?.toString() ?? "-"),
            _rowInfo("Jumlah alat", "${listAlat.length} unit"),
            _rowInfo("Pengambilan", _formatTgl(widget.data['pengambilan'])),
            _rowInfo("Tenggat", _formatTgl(widget.data['tenggat'])),
            
            // Kolom Input Pengembalian
            const SizedBox(height: 15),
            const Align(alignment: Alignment.centerLeft, child: Text("Pengembalian", style: TextStyle(fontWeight: FontWeight.w500))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _datePicker()),
                const SizedBox(width: 10),
                Expanded(child: _timePicker()),
              ],
            ),
            const Divider(height: 40),
            _rowInfo("Terlambat", hariTerlambat > 0 ? "$hariTerlambat Hari" : "-"),
            _rowInfo("Nominal denda", denda > 0 ? "Rp $denda" : "-"),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F3C58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                onPressed: _konfirmasiPengembalian,
                child: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
              ),
            ),
            if (isSuccess) _statusBerhasil(),
          ],
        ),
      ),
    );
  }

  // Widget pendukung tampilan (UI)
  Widget _cardAlat(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        const Icon(Icons.image, size: 50, color: Colors.grey),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['alat']['nama_alat'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("Alat", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text("${item['jumlah']} unit", style: const TextStyle(fontSize: 11)),
        ])
      ]),
    );
  }

  Widget _rowInfo(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    ]),
  );

  Widget _datePicker() => InkWell(
    onTap: () async {
      DateTime? p = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2025), lastDate: DateTime(2030));
      if (p != null) { setState(() => selectedDate = p); _hitungDendaOtomatis(); }
    },
    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1F3C58)), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [const Icon(Icons.calendar_month, size: 18), const SizedBox(width: 10), Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontSize: 12))])),
  );

  Widget _timePicker() => InkWell(
    onTap: () async {
      TimeOfDay? p = await showTimePicker(context: context, initialTime: selectedTime);
      if (p != null) { setState(() => selectedTime = p); _hitungDendaOtomatis(); }
    },
    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1F3C58)), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [const Icon(Icons.access_time, size: 18), const SizedBox(width: 10), Text(selectedTime.format(context), style: const TextStyle(fontSize: 12))])),
  );

  Widget _statusBerhasil() => Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(20)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline, color: Colors.green, size: 18), SizedBox(width: 10), Text("Berhasil", style: TextStyle(color: Colors.green))]),
  );

  String _formatTgl(dynamic d) => d != null ? DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.parse(d.toString())) : "-";
}