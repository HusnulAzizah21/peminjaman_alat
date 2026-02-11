import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';

class TransaksiPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const TransaksiPage({super.key, required this.cartItems});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final c = Get.find<AppController>();

  final TextEditingController tglAmbilController = TextEditingController();
  final TextEditingController jamAmbilController = TextEditingController();
  final TextEditingController tglTenggatController = TextEditingController();
  final TextEditingController jamTenggatController = TextEditingController();

  DateTime? selectedTglAmbil;
  TimeOfDay? selectedJamAmbil;
  DateTime? selectedTglTenggat;
  TimeOfDay? selectedJamTenggat;

  Future<void> _selectDate(BuildContext context, bool isAmbil) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isAmbil) {
          selectedTglAmbil = picked;
          tglAmbilController.text = DateFormat('dd MMMM yyyy').format(picked);
        } else {
          selectedTglTenggat = picked;
          tglTenggatController.text = DateFormat('dd MMMM yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isAmbil) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      if (picked.hour > 17 || (picked.hour == 17 && picked.minute > 0)) {
        Get.snackbar("Waktu Dibatasi", "Maksimal jam adalah 17:00",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      setState(() {
        if (isAmbil) {
          selectedJamAmbil = picked;
          jamAmbilController.text = picked.format(context);
        } else {
          selectedJamTenggat = picked;
          jamTenggatController.text = picked.format(context);
        }
      });
    }
  }

  // ==========================================
  // FUNGSI AJUKAN (DENGAN PERBAIKAN ERROR)
  // ==========================================
  Future<void> _ajukanPeminjaman() async {
    // 1. Validasi Input Dasar
    if (selectedTglAmbil == null || selectedJamAmbil == null ||
        selectedTglTenggat == null || selectedJamTenggat == null) {
      Get.snackbar("Gagal", "Silakan lengkapi tanggal dan jam!",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // 2. Tampilkan Loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final userData = c.userProfile;
      if (userData.isEmpty || userData['id_user'] == null) {
        throw "Sesi login tidak valid. Silakan logout dan login kembali.";
      }

      final String idPeminjam = userData['id_user'];

      // ===========================================================
      // TAMBAHAN: VALIDASI 1 - CEK PINJAMAN AKTIF
      // ===========================================================
      final pinjamanAktif = await c.supabase
          .from('peminjaman')
          .select()
          .eq('id_peminjam', idPeminjam)
          // KODE YANG BENAR
          .inFilter('status_transaksi', ['menunggu', 'disetujui', 'pinjam']);

      if ((pinjamanAktif as List).isNotEmpty) {
        Get.back(); // Tutup loading
        Get.snackbar("Gagal Meminjam", "Anda masih memiliki peminjaman yang belum dikembalikan.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // ===========================================================
      // TAMBAHAN: VALIDASI 2 - CEK MAKSIMAL 1 PER ALAT
      // ===========================================================
      // ===========================================================
      // VALIDASI 2 - ATURAN STOK (Jika stok < 3, maks pinjam 1)
      // ===========================================================
      for (var item in widget.cartItems) {
        // Ambil data stok, pastikan default ke 0 jika null
        int stokTersedia = item['stok'] ?? 0;
        int jumlahPinjam = item['jumlah'] ?? 1;

        if (stokTersedia < 3 && jumlahPinjam > 1) {
          if (Get.isDialogOpen!) Get.back(); // Tutup loading
          Get.snackbar(
            "Batas Peminjaman", 
            "Stok ${item['nama_alat']} terbatas ($stokTersedia). Hanya boleh meminjam 1 unit.",
            backgroundColor: Colors.red, 
            colorText: Colors.white
          );
          return;
        }
      }
      // ===========================================================
      // ===========================================================

      DateTime combine(DateTime date, TimeOfDay time) =>
          DateTime(date.year, date.month, date.day, time.hour, time.minute);

      final DateTime waktuPengambilan = combine(selectedTglAmbil!, selectedJamAmbil!);
      final DateTime waktuTenggat = combine(selectedTglTenggat!, selectedJamTenggat!);

      // 3. Insert ke tabel 'peminjaman' (Header)
      final insertPeminjaman = await c.supabase
          .from('peminjaman')
          .insert({
            'id_peminjam': idPeminjam,
            'pengambilan': waktuPengambilan.toIso8601String(),
            'tenggat': waktuTenggat.toIso8601String(),
            'status_transaksi': 'menunggu',
          })
          .select()
          .single();

      final idPinjam = insertPeminjaman['id_pinjam'];

      // 4. Batch Detail
      final List<Map<String, dynamic>> batchDetails = widget.cartItems.map((item) {
        return {
          'id_pinjam': idPinjam,
          'id_alat': item['id_alat'],
          'jumlah': item['jumlah'] ?? 1,
        };
      }).toList();

      // 5. Insert Detail
      await c.supabase.from('detail_peminjaman').insert(batchDetails);

      // 6. Tutup Loading & Notifikasi Sukses
      Get.back(); // Tutup loading dialog
      
      Get.snackbar("Berhasil", "Pengajuan dikirim!",
          backgroundColor: Colors.green, colorText: Colors.white);

      Future.delayed(const Duration(seconds: 1), () {
        Get.back(); // Kembali ke halaman katalog/keranjang
      });

    } catch (e) {
      if (Get.isDialogOpen!) Get.back(); // Tutup loading jika error
      print("DETAIL ERROR: $e");
      Get.snackbar("Error", "Gagal mengirim: $e", 
          backgroundColor: Color(0xFF1F3C58), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1F3C58);
    final userData = c.userProfile;
    final String userName = userData['nama'] ?? "User";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Pengajuan",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Alat yang dipinjam",
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          item['gambar_url'] ?? "",
                          width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.image),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama_alat'] ?? "",
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(item['nama_kategori'] ?? "",
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text("${item['jumlah'] ?? 1} unit",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                );
              },
            ),
            const Divider(height: 30),
            _infoRow("Nama", userName),
            _infoRow("Total Unit", "${widget.cartItems.length} unit"),
            const SizedBox(height: 20),
            const Text("Pengambilan", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                _dateBox(tglAmbilController, Icons.calendar_month, () => _selectDate(context, true)),
                const SizedBox(width: 10),
                _dateBox(jamAmbilController, Icons.access_time, () => _selectTime(context, true)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Tenggat (Estimasi Balik)", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                _dateBox(tglTenggatController, Icons.calendar_month, () => _selectDate(context, false)),
                const SizedBox(width: 10),
                _dateBox(jamTenggatController, Icons.access_time, () => _selectTime(context, false)),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _ajukanPeminjaman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Ajukan peminjaman",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
        ],
      ),
    );
  }

  Widget _dateBox(TextEditingController controller, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: IgnorePointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF1F3C58)),
              hintText: icon == Icons.calendar_month ? "Tanggal" : "Jam",
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ),
    );
  }
}