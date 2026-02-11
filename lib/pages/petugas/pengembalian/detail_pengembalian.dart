import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/app_controller.dart';

// =========================================================
// 1. DATA MODELS
// =========================================================
class Peminjaman {
  final int idPinjam;
  final String idPeminjam;
  final String? tenggat;

  Peminjaman.fromMap(Map<String, dynamic> map)
      : idPinjam = int.tryParse(map['id_pinjam']?.toString() ?? '0') ?? 0,
        idPeminjam = map['id_peminjam']?.toString() ?? '',
        tenggat = map['tenggat']?.toString();

  DateTime? get tenggatDate => tenggat != null ? DateTime.tryParse(tenggat!) : null;
}

class StatusPinjam {
  static const String dipinjam = 'dipinjam';
  static const String selesai = 'selesai';
  static const String terlambat = 'terlambat';
  }

class AlatDipinjam {
  final int jumlah;
  final String namaAlat;
  final String? kategori;

  AlatDipinjam({required this.jumlah, required this.namaAlat, this.kategori});

  factory AlatDipinjam.fromDetailMap(Map<String, dynamic> detail) {
    final dynamic alatData = detail['alat'];
    final Map<String, dynamic> alatMap = (alatData is Map) ? Map<String, dynamic>.from(alatData) : {};
    
    final dynamic kategoriData = alatMap['kategori'];
    final Map<String, dynamic> kategoriMap = (kategoriData is Map) ? Map<String, dynamic>.from(kategoriData) : {};

    return AlatDipinjam(
      jumlah: int.tryParse(detail['jumlah']?.toString() ?? '0') ?? 0,
      namaAlat: alatMap['nama_alat']?.toString() ?? 'Alat Tidak Diketahui',
      kategori: kategoriMap['nama_kategori']?.toString() ?? '-',
    );
  }
}

// =========================================================
// 2. CONTROLLER
// =========================================================
class DetailPengembalianController extends GetxController {
  final SupabaseClient supabase = Get.find<AppController>().supabase;
  final Peminjaman pinjam;

  var namaPeminjam = 'Memuat...'.obs;
  var alatList = <AlatDipinjam>[].obs;
  var isLoading = true.obs;
  
  var hariTerlambat = 0.obs;
  var nominalDenda = 0.obs; 

  var tglKembali = DateTime.now().obs;
  var waktuKembali = TimeOfDay.now().obs;

  DetailPengembalianController(this.pinjam);

  @override
  void onInit() {
    super.onInit();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      isLoading.value = true;
      final userRes = await supabase.from('users').select('nama').eq('id_user', pinjam.idPeminjam).maybeSingle();
      namaPeminjam.value = userRes?['nama']?.toString() ?? 'User';

      final detailRes = await supabase.from('detail_peminjaman').select('''
        jumlah,
        alat (nama_alat, kategori (nama_kategori))
      ''').eq('id_pinjam', pinjam.idPinjam);
      
      if (detailRes != null) {
        final list = (detailRes as List).map((e) => AlatDipinjam.fromDetailMap(e)).toList();
        alatList.assignAll(list);
      }
    } catch (e) {
      debugPrint("Error Fetch: $e");
    } finally {
      isLoading.value = false;
      hitungDenda();
    }
  }

  void hitungDenda() {
    final tg = pinjam.tenggatDate;
    if (tg == null) return;

    final skrg = DateTime(
      tglKembali.value.year, 
      tglKembali.value.month, 
      tglKembali.value.day, 
      waktuKembali.value.hour, 
      waktuKembali.value.minute
    );

    if (skrg.isAfter(tg)) {
      final diff = skrg.difference(tg);
      int hari = diff.inDays;
      if (diff.inSeconds % 86400 > 0) hari += 1; 
      
      hariTerlambat.value = hari;
      nominalDenda.value = hari * 5000;
    } else {
      hariTerlambat.value = 0;
      nominalDenda.value = 0;
    }
  }

  Future<void> simpanData() async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      final tglSimpan = DateTime(
        tglKembali.value.year, 
        tglKembali.value.month, 
        tglKembali.value.day, 
        waktuKembali.value.hour, 
        waktuKembali.value.minute
      );

      // 1. Update status di tabel Peminjaman
      await supabase.from('peminjaman').update({
        'pengembalian': tglSimpan.toIso8601String(),
        'status_transaksi': 'selesai', // Pastikan teks ini sesuai dengan Enum di database
      }).eq('id_pinjam', pinjam.idPinjam);

      // 2. Simpan ke tabel Denda (Hanya kolom yang diizinkan)
      if (hariTerlambat.value > 0) {
        await supabase.from('denda').upsert({
          'pengembalian': pinjam.idPinjam, 
          'hari_terlambat': hariTerlambat.value,
          'tarif_per_hari': 5000,
          // nominal_denda TIDAK BOLEH dikirim karena 'generated column'
        }, onConflict: 'pengembalian'); 
      }

      if (Get.isDialogOpen!) Get.back(); 
      Get.back(result: true); 

      Get.snackbar("Berhasil", "Data pengembalian berhasil disimpan",
        backgroundColor: Colors.green, colorText: Colors.white);
        
    } catch (e) {
      if (Get.isDialogOpen!) Get.back(); 
      debugPrint("Error Simpan: $e");
      
      // Tips: Jika masih error enum, pastikan 'selesai' ada di database. 
      // Jika error 42P10 tetap muncul, pastikan langkah SQL nomor 1 sudah sukses.
      Get.snackbar("Gagal", "Terjadi kesalahan: $e", 
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  }

// =========================================================
// 3. VIEW
// =========================================================
class DetailPengembalianAktifPage extends StatelessWidget {
  final Map<String, dynamic> rawData;
  const DetailPengembalianAktifPage({super.key, required this.rawData});

  @override
  Widget build(BuildContext context) {
    final p = Peminjaman.fromMap(rawData);
    final c = Get.put(DetailPengembalianController(p), tag: p.idPinjam.toString());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Pengembalian", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F3C58),
        elevation: 0,
      ),
      body: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("Alat yang Dipinjam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildListAlat(c),
            const SizedBox(height: 25),
            _infoRow("Nama ", c.namaPeminjam.value),
            _infoRow("Tenggat ", p.tenggatDate != null 
                ? DateFormat('dd MMM yyyy, HH:mm').format(p.tenggatDate!) : '-'),
            const Divider(height: 40),
            
            const Text("Pengembalian", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildDateTimePicker(context, c),
            const SizedBox(height: 25),
            _buildDendaSection(c),
            const SizedBox(height: 30),
            _buildSubmitButton(c),
          ],
        );
      }),
    );
  }

  Widget _buildListAlat(DetailPengembalianController c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        children: c.alatList.map((item) => ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(item.namaAlat, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item.kategori ?? '-'),
          trailing: Text("${item.jumlah} unit", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context, DetailPengembalianController c) {
    // Obx diletakkan di dalam fungsi agar hanya bagian ini yang dirender ulang saat waktu berubah
    return Obx(() => Row(
      children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: c.tglKembali.value, firstDate: DateTime(2024), lastDate: DateTime(2030));
            if (d != null) { c.tglKembali.value = d; c.hitungDenda(); }
          },
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(DateFormat('dd/MM/yyyy').format(c.tglKembali.value)),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(
          onPressed: () async {
            final t = await showTimePicker(context: context, initialTime: c.waktuKembali.value);
            if (t != null) { c.waktuKembali.value = t; c.hitungDenda(); }
          },
          icon: const Icon(Icons.access_time, size: 18),
          label: Text(c.waktuKembali.value.format(context)),
        )),
      ],
    ));
  }

  Widget _buildDendaSection(DetailPengembalianController c) {
    return Obx(() {
      final bool terlambat = c.hariTerlambat.value > 0;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: terlambat ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: terlambat ? Colors.red.shade200 : Colors.green.shade200)
        ),
        child: Column(
          children: [
            _statusRow("Terlambat", "${c.hariTerlambat.value} Hari", terlambat),
            const Divider(),
            _statusRow("Total Denda", c.nominalDenda.value.toIdr(), terlambat),
          ],
        ),
      );
    });
  }

  Widget _buildSubmitButton(DetailPengembalianController c) {
    return ElevatedButton(
      onPressed: () => c.simpanData(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F3C58),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      child: const Text("KONFIRMASI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
    ),
  );

  Widget _statusRow(String label, String value, bool isRed) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: isRed ? Colors.red.shade700 : Colors.green.shade700)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isRed ? Colors.red.shade900 : Colors.green.shade900)),
    ],
  );
}

// =========================================================
// 4. EXTENSIONS
// =========================================================
extension CurrencyFormatter on int {
  String toIdr() {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(this);
  }
}