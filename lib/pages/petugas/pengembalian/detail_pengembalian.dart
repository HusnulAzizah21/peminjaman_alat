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
    _fetchDetailAlat();
    _hitungDendaOtomatis();
  }

  // 1. Relasi Tabel: Mengambil Detail Alat + Nama Kategori
  Future<void> _fetchDetailAlat() async {
    try {
      final res = await c.supabase
          .from('detail_peminjaman')
          .select('jumlah, alat(nama_alat, kategori(nama_kategori))')
          .eq('id_pinjam', widget.data['id_pinjam']);
      setState(() {
        listAlat = res;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Fetch Detail: $e");
    }
  }

  // 2. Relasi Tabel: Mengambil Nama User dari UUID id_peminjam
  Future<String> _getNamaPeminjam() async {
    try {
      final res = await c.supabase
          .from('users')
          .select('nama')
          .eq('id_user', widget.data['id_peminjam'])
          .maybeSingle();
      return res != null ? res['nama'] : "User Tidak Dikenal";
    } catch (e) {
      return "Error User";
    }
  }

  void _hitungDendaOtomatis() {
    if (widget.data['tenggat'] == null) return;

    DateTime tenggat = DateTime.parse(widget.data['tenggat']);
    DateTime tglKembali = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute
    );

    if (tglKembali.isAfter(tenggat)) {
      int selisih = tglKembali.difference(tenggat).inDays;
      // Logika: Jika hari yang sama tapi jam lewat, dianggap terlambat 1 hari
      if (tglKembali.isAfter(tenggat) && selisih == 0) selisih = 1;
      
      setState(() {
        hariTerlambat = selisih;
        denda = hariTerlambat * 5000; 
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
      String waktuSelesai = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day,
        selectedTime.hour, selectedTime.minute
      ).toIso8601String();

      await c.supabase.from('peminjaman').update({
        'status_transaksi': 'selesai',
        'waktu_kembali': waktuSelesai, // Sesuai kolom di RiwayatPage tadi
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
            // List Barang dengan Relasi Kategori
            ...listAlat.map((item) => _cardAlat(item)).toList(),
            const Divider(height: 30),
            
            // Info Nama User (Hasil Relasi)
            FutureBuilder<String>(
              future: _getNamaPeminjam(),
              builder: (context, snapshot) {
                return _rowInfo("Peminjam", snapshot.data ?? "Memuat...");
              }
            ),
            
            _rowInfo("Total Item", "${listAlat.length} Jenis Alat"),
            _rowInfo("Waktu Pinjam", _formatTgl(widget.data['waktu_pinjam'])),
            _rowInfo("Tenggat", _formatTgl(widget.data['tenggat'])),
            
            const SizedBox(height: 15),
            const Align(alignment: Alignment.centerLeft, child: Text("Tanggal Pengembalian", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _datePicker()),
                const SizedBox(width: 10),
                Expanded(child: _timePicker()),
              ],
            ),
            const Divider(height: 40),
            _rowInfo("Keterlambatan", hariTerlambat > 0 ? "$hariTerlambat Hari" : "-"),
            _rowInfo("Total Denda", denda > 0 ? "Rp ${NumberFormat('#,###').format(denda)}" : "Rp 0"),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3C58), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: _konfirmasiPengembalian,
                child: const Text("Konfirmasi Selesai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            if (isSuccess) _statusBerhasil(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _cardAlat(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.inventory_2_outlined, size: 30, color: Color(0xFF1F3C58)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              item['alat']['nama_alat'] ?? "-", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item['alat']['kategori']['nama_kategori'] ?? "Kategori", 
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey)
            ),
            Text("${item['jumlah']} unit", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
          ]),
        )
      ]),
    );
  }

  Widget _rowInfo(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _datePicker() => InkWell(
    onTap: () async {
      DateTime? p = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2024), lastDate: DateTime(2030));
      if (p != null) { setState(() => selectedDate = p); _hitungDendaOtomatis(); }
    },
    child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [const Icon(Icons.calendar_month, size: 18, color: Colors.grey), const SizedBox(width: 10), Text(DateFormat('dd MMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 12))])),
  );

  Widget _timePicker() => InkWell(
    onTap: () async {
      TimeOfDay? p = await showTimePicker(context: context, initialTime: selectedTime);
      if (p != null) { setState(() => selectedTime = p); _hitungDendaOtomatis(); }
    },
    child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [const Icon(Icons.access_time, size: 18, color: Colors.grey), const SizedBox(width: 10), Text(selectedTime.format(context), style: const TextStyle(fontSize: 12))])),
  );

  Widget _statusBerhasil() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.green)),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text("Pengembalian Berhasil Dicatat", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
  );

  String _formatTgl(dynamic d) => d != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(d.toString()).toLocal()) : "-";
}