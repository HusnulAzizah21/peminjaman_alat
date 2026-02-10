import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../controllers/app_controller.dart';

// ────────────────────────────────────────────────
// MODEL
// ────────────────────────────────────────────────

class RiwayatPeminjaman {
  final int idPinjam;
  final String idPeminjam;
  final String? pengambilan;
  final String? tenggat;
  final String? pengembalian;

  RiwayatPeminjaman.fromMap(Map<String, dynamic> map)
      : idPinjam = map['id_pinjam'] as int,
        idPeminjam = map['id_peminjam'] as String,
        pengambilan = map['pengambilan'] as String?,
        tenggat = map['tenggat'] as String?,
        pengembalian = map['pengembalian'] as String?;

  DateTime? get pengambilanDate => pengambilan != null ? DateTime.parse(pengambilan!) : null;
  DateTime? get tenggatDate => tenggat != null ? DateTime.parse(tenggat!) : null;
  DateTime? get pengembalianDate => pengembalian != null ? DateTime.parse(pengembalian!) : null;
}

class AlatDikembalikan {
  final int jumlah;
  final String namaAlat;
  final String? namaKategori;

  AlatDikembalikan({
    required this.jumlah,
    required this.namaAlat,
    this.namaKategori,
  });

  factory AlatDikembalikan.fromMap(Map<String, dynamic> detail) {
    final alat = detail['alat'] as Map<String, dynamic>? ?? {};
    final kategori = alat['kategori'] as Map<String, dynamic>? ?? {};

    return AlatDikembalikan(
      jumlah: detail['jumlah'] as int? ?? 1,
      namaAlat: alat['nama_alat'] as String? ?? 'Alat tidak diketahui',
      namaKategori: kategori['nama_kategori'] as String? ?? '-',
    );
  }
}

class DendaInfo {
  final int hariTerlambat;
  final int nominal;

  DendaInfo({required this.hariTerlambat, required this.nominal});

  String get formattedNominal => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(nominal);
}

// ────────────────────────────────────────────────
// SERVICE
// ────────────────────────────────────────────────

class RiwayatService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<String?> getNamaPeminjam(String idPeminjam) async {
    try {
      final res = await supabase
          .from('users')
          .select('nama')
          .eq('id_user', idPeminjam)
          .maybeSingle();
      return res?['nama'] as String?;
    } catch (e) {
      debugPrint('Error ambil nama: $e');
      return null;
    }
  }

  Future<List<AlatDikembalikan>> getDaftarAlat(int idPinjam) async {
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

      return res.map((e) => AlatDikembalikan.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error ambil alat: $e');
      return [];
    }
  }

  DendaInfo hitungDenda(DateTime? tenggat, DateTime? kembali) {
    if (tenggat == null || kembali == null) {
      return DendaInfo(hariTerlambat: 0, nominal: 0);
    }

    if (kembali.isAfter(tenggat)) {
      final selisih = kembali.difference(tenggat).inDays;
      final hari = selisih > 0 ? selisih : 0;
      return DendaInfo(hariTerlambat: hari, nominal: hari * 5000);
    }

    return DendaInfo(hariTerlambat: 0, nominal: 0);
  }
}

// ────────────────────────────────────────────────
// CONTROLLER
// ────────────────────────────────────────────────

class DetailRiwayatController extends GetxController {
  final RiwayatService service = RiwayatService();
  final RiwayatPeminjaman riwayat;

  final RxString namaPeminjam = 'Memuat...'.obs;
  final RxList<AlatDikembalikan> alatList = <AlatDikembalikan>[].obs;
  final RxBool isLoading = true.obs;

  late final DendaInfo denda;

  DetailRiwayatController(this.riwayat) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Nama peminjam
      final nama = await service.getNamaPeminjam(riwayat.idPeminjam);
      namaPeminjam.value = nama ?? 'Tidak diketahui';

      // Daftar alat
      final alat = await service.getDaftarAlat(riwayat.idPinjam);
      alatList.assignAll(alat);

      // Denda
      denda = service.hitungDenda(riwayat.tenggatDate, riwayat.pengembalianDate);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data');
    } finally {
      isLoading.value = false;
    }
  }

  int get totalAlat => alatList.fold(0, (sum, e) => sum + e.jumlah);
}

// ────────────────────────────────────────────────
// PAGE
// ────────────────────────────────────────────────

class DetailPengembalianSelesaiPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailPengembalianSelesaiPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final riwayat = RiwayatPeminjaman.fromMap(data);
    final controller = Get.put(DetailRiwayatController(riwayat));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F3C58)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Detail Riwayat",
          style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daftar alat (tanpa gambar)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: controller.alatList.map((alat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2, color: Colors.grey),
                          ),
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
                                  alat.namaKategori ?? '-',
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

              // Info peminjam & tanggal
              _infoTile("Nama", controller.namaPeminjam.value),
              _infoTile("Jumlah alat", "${controller.totalAlat} unit"),

              const SizedBox(height: 16),
              _infoTile("Pengambilan", riwayat.pengambilanDate != null
                  ? DateFormat('dd/MM/yyyy – HH:mm').format(riwayat.pengambilanDate!)
                  : '-'),
              _infoTile("Tenggat", riwayat.tenggatDate != null
                  ? DateFormat('dd/MM/yyyy – HH:mm').format(riwayat.tenggatDate!)
                  : '-'),
              _infoTile("Pengembalian", riwayat.pengembalianDate != null
                  ? DateFormat('dd/MM/yyyy – HH:mm').format(riwayat.pengembalianDate!)
                  : '-'),

              const SizedBox(height: 24),

              // Bagian terlambat & denda (persis seperti gambar)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Terlambat",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${controller.denda.hariTerlambat} hari",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.redAccent, thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total denda",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        controller.denda.formattedNominal,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tombol Selesai
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1F3C58), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Selesai",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3C58),
                    ),
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
}