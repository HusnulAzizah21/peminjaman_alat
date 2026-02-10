import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/app_controller.dart';

// ────────────────────────────────────────────────
// 1. MODEL (SANGAT AMAN DARI NULL)
// ────────────────────────────────────────────────

class Peminjaman {
  final int idPinjam;
  final String idPeminjam;
  final String? pengambilan;
  final String? tenggat;

  Peminjaman.fromMap(Map<String, dynamic> map)
      : idPinjam = int.tryParse(map['id_pinjam']?.toString() ?? '0') ?? 0,
        idPeminjam = map['id_peminjam']?.toString() ?? '',
        pengambilan = map['pengambilan']?.toString(),
        tenggat = map['tenggat']?.toString();

  DateTime? get tenggatDate => tenggat != null ? DateTime.tryParse(tenggat!) : null;
}

class AlatDipinjam {
  final int jumlah;
  final String namaAlat;
  final String kategori;

  AlatDipinjam({required this.jumlah, required this.namaAlat, required this.kategori});

  factory AlatDipinjam.fromDetailMap(Map<String, dynamic> detail) {
    try {
      // Ambil data alat & kategori dengan proteksi null bertingkat
      final alat = detail['alat'] as Map<String, dynamic>? ?? {};
      final kat = alat['kategori'] as Map<String, dynamic>? ?? {};

      return AlatDipinjam(
        // Cek dua kemungkinan nama kolom: 'jumlah' atau 'jumlahpinjam'
        jumlah: int.tryParse(detail['jumlah']?.toString() ?? detail['jumlahpinjam']?.toString() ?? '1') ?? 1,
        namaAlat: alat['nama_alat']?.toString() ?? 'Alat Tidak Dikenal',
        kategori: kat['nama_kategori']?.toString() ?? '-',
      );
    } catch (e) {
      return AlatDipinjam(jumlah: 1, namaAlat: 'Error Load Data', kategori: '-');
    }
  }
}

// ────────────────────────────────────────────────
// 2. SERVICE
// ────────────────────────────────────────────────

class PengembalianService {
  final SupabaseClient supabase;
  PengembalianService(this.supabase);

  Future<String> getNamaPeminjam(String id) async {
    try {
      final res = await supabase.from('users').select('nama').eq('id_user', id).maybeSingle();
      return res?['nama']?.toString() ?? 'Tanpa Nama';
    } catch (e) { return 'Error User'; }
  }

  Future<List<AlatDipinjam>> getDaftarAlat(int idPinjam) async {
    try {
      final res = await supabase.from('detail_peminjaman').select('''
        jumlah,
        alat (
          nama_alat,
          kategori (nama_kategori)
        )
      ''').eq('id_pinjam', idPinjam);
      
      if (res == null) return [];
      return (res as List).map((e) => AlatDipinjam.fromDetailMap(e)).toList();
    } catch (e) {
      debugPrint("Gagal Select: $e");
      return [];
    }
  }
}

// ────────────────────────────────────────────────
// 3. CONTROLLER
// ────────────────────────────────────────────────

class DetailPengembalianController extends GetxController {
  final PengembalianService service;
  final Peminjaman pinjam;

  final RxString namaPeminjam = '...'.obs;
  final RxList<AlatDipinjam> alatList = <AlatDipinjam>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt hariTerlambat = 0.obs;
  final RxInt nominalDenda = 0.obs;

  // Input
  final Rx<DateTime> tglKembali = DateTime.now().obs;
  final Rx<TimeOfDay> wktKembali = TimeOfDay.now().obs;

  DetailPengembalianController(this.service, this.pinjam);

  @override
  void onInit() {
    super.onInit();
    _fetchData();
  }

  Future<void> _fetchData() async {
    isLoading.value = true;
    try {
      namaPeminjam.value = await service.getNamaPeminjam(pinjam.idPeminjam);
      final list = await service.getDaftarAlat(pinjam.idPinjam);
      alatList.assignAll(list);
    } finally {
      isLoading.value = false;
      hitungDenda();
    }
  }

  void hitungDenda() {
    final tg = pinjam.tenggatDate;
    if (tg == null) return;

    final skrg = DateTime(tglKembali.value.year, tglKembali.value.month, tglKembali.value.day, 
                          wktKembali.value.hour, wktKembali.value.minute);

    if (skrg.isAfter(tg)) {
      final diff = skrg.difference(tg);
      int hari = diff.inDays;
      if (diff.inSeconds % 86400 > 0) hari += 1; // Telat dikit = tambah 1 hari
      
      hariTerlambat.value = hari;
      nominalDenda.value = hari * 5000;
    } else {
      hariTerlambat.value = 0;
      nominalDenda.value = 0;
    }
  }

  Future<void> simpan() async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      final tglFinal = DateTime(tglKembali.value.year, tglKembali.value.month, tglKembali.value.day, 
                                wktKembali.value.hour, wktKembali.value.minute);

      await service.supabase.from('peminjaman').update({
        'status_transaksi': 'selesai',
        'pengembalian': tglFinal.toIso8601String(),
      }).eq('id_pinjam', pinjam.idPinjam);

      if (nominalDenda.value > 0) {
        await service.supabase.from('denda').insert({
          'id_pinjam': pinjam.idPinjam,
          'hari_terlambat': hariTerlambat.value,
          'nominal_denda': nominalDenda.value,
        });
      }

      Get.back(); // Tutup Loading
      Get.back(); // Kembali
      Get.snackbar("Berhasil", "Data pengembalian disimpan", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.back();
      Get.snackbar("Gagal", "Error: $e");
    }
  }
}

// ────────────────────────────────────────────────
// 4. VIEW (TAMPILAN)
// ────────────────────────────────────────────────

class DetailPengembalianAktifPage extends StatelessWidget {
  final Map<String, dynamic> rawData;
  const DetailPengembalianAktifPage({super.key, required this.rawData});

  @override
  Widget build(BuildContext context) {
    final p = Peminjaman.fromMap(rawData);
    final c = Get.put(DetailPengembalianController(
      PengembalianService(Get.find<AppController>().supabase), p
    ), tag: p.idPinjam.toString());

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Pengembalian")),
      body: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("Alat Dipinjam", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Box Daftar Alat
            Container(
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: c.alatList.map((item) => ListTile(
                  leading: const Icon(Icons.build_circle),
                  title: Text(item.namaAlat),
                  subtitle: Text(item.kategori),
                  trailing: Text("${item.jumlah} Unit"),
                )).toList(),
              ),
            ),

            const SizedBox(height: 20),
            _infoRow("Peminjam", c.namaPeminjam.value),
            _infoRow("Tenggat", p.tenggatDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(p.tenggatDate!) : '-'),
            
            const Divider(height: 40),
            
            const Text("Waktu Kembali Sebenarnya:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: c.tglKembali.value, firstDate: DateTime(2020), lastDate: DateTime(2100));
                    if (d != null) { c.tglKembali.value = d; c.hitungDenda(); }
                  },
                  child: Text(DateFormat('dd/MM/yyyy').format(c.tglKembali.value)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: c.wktKembali.value);
                    if (t != null) { c.wktKembali.value = t; c.hitungDenda(); }
                  },
                  child: Text(c.wktKembali.value.format(context)),
                )),
              ],
            ),

            const SizedBox(height: 30),
            
            // Panel Denda
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: c.hariTerlambat.value > 0 ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(10)
              ),
              child: Column(
                children: [
                  _infoRow("Keterlambatan", "${c.hariTerlambat.value} Hari"),
                  _infoRow("Total Denda", (c.nominalDenda.value).toIDR()),
                ],
              ),
            ),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => c.simpan(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F3C58), padding: const EdgeInsets.all(15)),
              child: const Text("KONFIRMASI SEKARANG", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      }),
    );
  }

  Widget _infoRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l), Text(v, style: const TextStyle(fontWeight: FontWeight.bold))]),
  );
}

extension on int {
  String toIDR() => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(this);
}