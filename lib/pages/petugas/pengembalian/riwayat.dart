import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class RiwayatPengembalian extends StatefulWidget {
  final Map<String, dynamic> data;
  const RiwayatPengembalian({super.key, required this.data});

  @override
  State<RiwayatPengembalian> createState() => RiwayatPengembalianState();
}

class RiwayatPengembalianState extends State<RiwayatPengembalian> {
  final c = Get.find<AppController>();
  
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  
  int hariTerlambat = 0;
  int denda = 0;
  bool isSuccess = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _hitungDenda(); // Hitung awal saat halaman dibuka
  }

  void _hitungDenda() {
    if (widget.data['tenggat_kembali'] == null) return;

    DateTime tenggat = DateTime.parse(widget.data['tenggat_kembali']);
    DateTime inputUser = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 
        selectedTime.hour, selectedTime.minute);

    if (inputUser.isAfter(tenggat)) {
      int selisih = inputUser.difference(tenggat).inDays;
      // Proteksi jika lewat hari tapi inDays masih 0
      if (inputUser.day != tenggat.day && selisih == 0) selisih = 1;

      setState(() {
        hariTerlambat = selisih > 0 ? selisih : 0;
        denda = hariTerlambat * 5000; // Hardcode tarif
      });
    } else {
      setState(() { hariTerlambat = 0; denda = 0; });
    }
  }

  Future<void> _konfirmasi() async {
    setState(() => isLoading = true);
    try {
      // 1. Simpan denda ke tabel denda jika terlambat
      if (denda > 0) {
        await c.supabase.from('denda').insert({
          'pengembalian': widget.data['id_pinjam'],
          'hari_terlambat': hariTerlambat,
          'tarif_per_hari': 5000,
        });
      }

      // 2. Update status transaksi
      await c.supabase.from('peminjaman').update({
        'status_transaksi': 'selesai',
        'tgl_kembali_real': DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day, 
            selectedTime.hour, selectedTime.minute).toIso8601String(),
      }).eq('id_pinjam', widget.data['id_pinjam']);

      setState(() {
        isSuccess = true;
        isLoading = false;
      });
      
      // Delay agar user melihat status "Berhasil" sesuai gambar
      Future.delayed(const Duration(seconds: 2), () => Get.back());
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F3C58)), 
            onPressed: () => Get.back()),
        title: const Text("Pengembalian", 
            style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _barangCard("Kamera", "Elektronika"),
            _barangCard("Proyektor", "Elektronika"),
            
            const Divider(height: 40),
            _infoRow("Nama", widget.data['id_peminjam']?.toString() ?? "-"),
            _infoRow("Jumlah alat", "2 unit"),
            _infoRow("Pengambilan", _formatTgl(widget.data['created_at'])),
            _infoRow("Tenggat", _formatTgl(widget.data['tenggat_kembali'])),
            
            const SizedBox(height: 15),
            const Align(alignment: Alignment.centerLeft, 
                child: Text("Pengembalian", style: TextStyle(fontWeight: FontWeight.w500))),
            const SizedBox(height: 10),
            
            // Input Tanggal & Waktu
            Row(
              children: [
                Expanded(child: _pickerBox(Icons.calendar_month, 
                    DateFormat('dd/MM/yyyy').format(selectedDate), _pickDate)),
                const SizedBox(width: 10),
                Expanded(child: _pickerBox(Icons.access_time_filled, 
                    "${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}", _pickTime)),
              ],
            ),
            
            const SizedBox(height: 20),
            _infoRow("Terlambat", hariTerlambat > 0 ? "$hariTerlambat Hari" : "-"),
            _infoRow("Nominal denda", denda > 0 ? "Rp $denda" : "-"),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3C58), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                onPressed: isLoading ? null : _konfirmasi,
                child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
              ),
            ),

            if (isSuccess) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.green), 
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 18), 
                    SizedBox(width: 10), 
                    Text("Berhasil", style: TextStyle(color: Colors.green))
                  ]),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _barangCard(String nama, String kat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 50, height: 50, color: Colors.white, child: const Icon(Icons.image, color: Colors.grey)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(kat, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const Text("1 unit", style: TextStyle(fontSize: 11)),
          ])
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: const TextStyle(fontSize: 13)), 
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
        ]),
    );
  }

  Widget _pickerBox(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1F3C58)), 
            borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF1F3C58)), 
          const SizedBox(width: 10), 
          Text(text, style: const TextStyle(fontSize: 12))
        ]),
      ),
    );
  }

  String _formatTgl(dynamic date) => date != null 
      ? DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.parse(date.toString())) 
      : "-";

  Future<void> _pickDate() async {
    DateTime? p = await showDatePicker(
        context: context, initialDate: selectedDate, 
        firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (p != null) { setState(() => selectedDate = p); _hitungDenda(); }
  }

  Future<void> _pickTime() async {
    TimeOfDay? p = await showTimePicker(context: context, initialTime: selectedTime);
    if (p != null) { setState(() => selectedTime = p); _hitungDenda(); }
  }
}