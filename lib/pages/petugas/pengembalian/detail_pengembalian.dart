import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/app_controller.dart';

// ────────────────────────────────────────────────
// 1. MODEL / DATA CLASS
// ────────────────────────────────────────────────

// Model untuk data peminjaman utama
class Peminjaman {
  final int idPinjam;
  final String idPeminjam;
  final String? pengambilan;     // tanggal pengambilan
  final String? tenggat;         // tanggal tenggat
  final String? statusTransaksi;

  Peminjaman.fromMap(Map<String, dynamic> map)
      : idPinjam = map['id_pinjam'] as int,
        idPeminjam = map['id_peminjam'] as String,
        pengambilan = map['pengambilan'] as String?,
        tenggat = map['tenggat'] as String?,
        statusTransaksi = map['status_transaksi'] as String?;

  // Helper untuk mengubah string tanggal menjadi DateTime
  DateTime? get pengambilanDate => pengambilan != null ? DateTime.parse(pengambilan!) : null;
  DateTime? get tenggatDate => tenggat != null ? DateTime.parse(tenggat!) : null;
}

// Model untuk setiap item alat yang dipinjam
class AlatDipinjam {
  final int jumlah;
  final String namaAlat;
  final String? kategori;

  AlatDipinjam({
    required this.jumlah,
    required this.namaAlat,
    this.kategori,
  });

  // Factory untuk parse data dari response Supabase (dari join)
  factory AlatDipinjam.fromDetailMap(Map<String, dynamic> detail) {
    final alatMap = detail['alat'] as Map<String, dynamic>? ?? {};
    final kategoriMap = alatMap['kategori'] as Map<String, dynamic>? ?? {};

    return AlatDipinjam(
      jumlah: detail['jumlah'] as int? ?? 1,
      namaAlat: alatMap['nama_alat'] as String? ?? 'Alat tidak diketahui',
      kategori: kategoriMap['nama_kategori'] as String? ?? '-',
    );
  }
}

// ────────────────────────────────────────────────
// 2. SERVICE / REPOSITORY (logika komunikasi database)
// ────────────────────────────────────────────────

class PengembalianService {
  final SupabaseClient supabase;

  PengembalianService(this.supabase);

  // Ambil nama peminjam dari tabel users
  Future<String?> getNamaPeminjam(String idPeminjam) async {
    try {
      final res = await supabase
          .from('users')
          .select('nama')
          .eq('id_user', idPeminjam)
          .maybeSingle();
      return res?['nama'] as String?;
    } catch (e) {
      debugPrint('Error ambil nama peminjam: $e');
      return null;
    }
  }

  // Ambil daftar alat yang dipinjam + join ke alat & kategori
  Future<List<AlatDipinjam>> getDaftarAlatDipinjam(int idPinjam) async {
    try {
      final res = await supabase
          .from('detail_peminjaman')
          .select('''
            jumlah,
            alat!inner (
              nama_alat,
              id_kategori,
              kategori!inner (
                nama_kategori
              )
            )
          ''')
          .eq('id_pinjam', idPinjam);

      return res.map((e) => AlatDipinjam.fromDetailMap(e)).toList();
    } catch (e) {
      debugPrint('Error ambil daftar alat: $e');
      return [];
    }
  }

  // Proses konfirmasi pengembalian (update status + simpan denda jika ada)
  Future<void> konfirmasiPengembalian({
    required int idPinjam,
    required DateTime tanggalKembali,
    required int nominalDenda,
  }) async {
    try {
      // 1. Update status peminjaman menjadi selesai
      await supabase.from('peminjaman').update({
        'status_transaksi': 'selesai',
        'pengembalian': tanggalKembali.toIso8601String(),
      }).eq('id_pinjam', idPinjam);

      // 2. Jika ada denda, simpan ke tabel denda
      if (nominalDenda > 0) {
        await supabase.from('denda').insert({
          'id_pinjam': idPinjam,
          'hari_terlambat': nominalDenda ~/ 5000,
          'nominal_denda': nominalDenda,
        });
      }
    } catch (e) {
      debugPrint('Error konfirmasi pengembalian: $e');
      rethrow;
    }
  }
}

// ────────────────────────────────────────────────
// 3. CONTROLLER / STATE MANAGEMENT
// ────────────────────────────────────────────────

class DetailPengembalianController extends GetxController {
  final PengembalianService service;
  final Peminjaman peminjaman;

  // State yang reaktif
  final RxString namaPeminjam = 'Memuat...'.obs;
  final RxList<AlatDipinjam> alatList = <AlatDipinjam>[].obs;
  final RxBool isLoading = true.obs;

  // Input tanggal & waktu pengembalian
  final Rx<DateTime> tanggalKembali = DateTime.now().obs;
  final Rx<TimeOfDay> waktuKembali = TimeOfDay.now().obs;

  // Hasil perhitungan denda
  final RxInt hariTerlambat = 0.obs;
  final RxInt nominalDenda = 0.obs;

  DetailPengembalianController({
    required this.service,
    required this.peminjaman,
  });

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  // Load data awal (nama peminjam + daftar alat)
  Future<void> _loadData() async {
    try {
      final nama = await service.getNamaPeminjam(peminjaman.idPeminjam);
      namaPeminjam.value = nama ?? 'Tidak diketahui';

      final alat = await service.getDaftarAlatDipinjam(peminjaman.idPinjam);
      alatList.assignAll(alat);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data');
    } finally {
      isLoading.value = false;
      _updateDenda();
    }
  }

  // Update tanggal → hitung ulang denda
  void updateTanggalKembali(DateTime date) {
    tanggalKembali.value = date;
    _updateDenda();
  }

  // Update waktu → hitung ulang denda
  void updateWaktuKembali(TimeOfDay time) {
    waktuKembali.value = time;
    _updateDenda();
  }

  // Logika hitung denda (5.000 per hari terlambat)
  void _updateDenda() {
    final tenggat = peminjaman.tenggatDate;
    if (tenggat == null) return;

    final returnDateTime = DateTime(
      tanggalKembali.value.year,
      tanggalKembali.value.month,
      tanggalKembali.value.day,
      waktuKembali.value.hour,
      waktuKembali.value.minute,
    );

    if (returnDateTime.isAfter(tenggat)) {
      final selisih = returnDateTime.difference(tenggat).inDays;
      hariTerlambat.value = selisih > 0 ? selisih : 0;
      nominalDenda.value = hariTerlambat.value * 5000;
    } else {
      hariTerlambat.value = 0;
      nominalDenda.value = 0;
    }
  }

  // ────────────────────────────────────────────────
  // PROSES KONFIRMASI PENGEMBALIAN (dipanggil dari tombol)
  // ────────────────────────────────────────────────
  Future<void> konfirmasiPengembalian() async {
    try {
      // Gabungkan tanggal + waktu menjadi satu DateTime
      final returnDateTime = DateTime(
        tanggalKembali.value.year,
        tanggalKembali.value.month,
        tanggalKembali.value.day,
        waktuKembali.value.hour,
        waktuKembali.value.minute,
      );

      // Panggil service untuk update database
      await service.konfirmasiPengembalian(
        idPinjam: peminjaman.idPinjam,
        tanggalKembali: returnDateTime,
        nominalDenda: nominalDenda.value,
      );

      // Feedback sukses
      Get.snackbar(
        'Sukses',
        'Pengembalian berhasil dikonfirmasi',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      // Kembali ke halaman sebelumnya
      Get.back();

    } catch (e) {
      debugPrint('Error konfirmasi: $e');
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan saat memproses pengembalian',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  int get totalAlat => alatList.fold(0, (sum, item) => sum + item.jumlah);
}

// ────────────────────────────────────────────────
// VIEW / HALAMAN UI
// ────────────────────────────────────────────────

class DetailPengembalianAktifPage extends StatelessWidget {
  final Map<String, dynamic> rawData;

  const DetailPengembalianAktifPage({super.key, required this.rawData});

  @override
  Widget build(BuildContext context) {
    final peminjaman = Peminjaman.fromMap(rawData);
    final controller = Get.put(
      DetailPengembalianController(
        service: PengembalianService(Get.find<AppController>().supabase),
        peminjaman: peminjaman,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pengembalian", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F3C58),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daftar alat (tanpa gambar)
              const Text("Alat yang Dipinjam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: controller.alatList.map((alat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: Colors.grey, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alat.namaAlat,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  alat.kategori ?? '-',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                                Text(
                                  "${alat.jumlah} unit",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Informasi dasar
              _infoTile("Nama Peminjam", controller.namaPeminjam.value),
              _infoTile("Tanggal Pengambilan", peminjaman.pengambilanDate != null
                  ? DateFormat('dd MMMM yyyy – HH:mm').format(peminjaman.pengambilanDate!)
                  : "-"),
              _infoTile("Tenggat Pengembalian", peminjaman.tenggatDate != null
                  ? DateFormat('dd MMMM yyyy – HH:mm').format(peminjaman.tenggatDate!)
                  : "-"),

              const SizedBox(height: 24),

              // Pilih tanggal & waktu pengembalian
              const Text("Tanggal Pengembalian", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _datePickerField(context, controller)),
                  const SizedBox(width: 12),
                  Expanded(child: _timePickerField(context, controller)),
                ],
              ),

              const SizedBox(height: 24),

              // Panel denda
              Obx(() => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: controller.hariTerlambat.value > 0 ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Terlambat", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 8),
                        Text(
                          "${controller.hariTerlambat.value} hari",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.redAccent, thickness: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total denda", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            Text(
                              controller.nominalDenda.value.toRupiah(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 32),

              // Tombol Konfirmasi Pengembalian
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.konfirmasiPengembalian,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3C58),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Konfirmasi Pengembalian",
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _datePickerField(BuildContext context, DetailPengembalianController c) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: c.tanggalKembali.value,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) c.updateTanggalKembali(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(c.tanggalKembali.value)),
            const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1F3C58)),
          ],
        ),
      ),
    );
  }

  Widget _timePickerField(BuildContext context, DetailPengembalianController c) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: c.waktuKembali.value,
        );
        if (picked != null) c.updateWaktuKembali(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(c.waktuKembali.value.format(context)),
            const Icon(Icons.access_time, size: 20, color: Color(0xFF1F3C58)),
          ],
        ),
      ),
    );
  }
}

// Extension untuk format Rupiah
extension IntRupiah on int {
  String toRupiah() => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(this);
}