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

  // Controller untuk tampilan di TextField
  final TextEditingController tglAmbilController = TextEditingController();
  final TextEditingController jamAmbilController = TextEditingController();
  final TextEditingController tglTenggatController = TextEditingController();
  final TextEditingController jamTenggatController = TextEditingController();

  // Variabel penyimpan data asli
  DateTime? selectedTglAmbil;
  TimeOfDay? selectedJamAmbil;
  DateTime? selectedTglTenggat;
  TimeOfDay? selectedJamTenggat;

  // 1. FUNGSI PILIH TANGGAL
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

  // 2. FUNGSI PILIH JAM (BATAS MAKSIMAL JAM 5 SORE)
  Future<void> _selectTime(BuildContext context, bool isAmbil) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      // Validasi: Jika lebih dari jam 17:00
      if (picked.hour > 17 || (picked.hour == 17 && picked.minute > 0)) {
        Get.snackbar("Waktu Dibatasi", "Maksimal peminjaman/pengembalian adalah jam 17:00",
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

  // 3. FUNGSI AJUKAN KE SUPABASE
  Future<void> _ajukanPeminjaman() async {
    if (selectedTglAmbil == null || selectedJamAmbil == null || 
        selectedTglTenggat == null || selectedJamTenggat == null) {
      Get.snackbar("Gagal", "Semua kolom tanggal dan waktu wajib diisi!");
      return;
    }

    try {
      final user = c.supabase.auth.currentUser;
      final String namaUser = user?.userMetadata?['nama'] ?? "User Tidak Dikenal";

      // Simpan data ke tabel 'peminjaman'
      await c.supabase.from('peminjaman').insert({
        'id_user': user?.id,
        'nama_user': namaUser,
        'tgl_pengambilan': selectedTglAmbil!.toIso8601String(),
        'jam_pengambilan': jamAmbilController.text,
        'tgl_tenggat': selectedTglTenggat!.toIso8601String(),
        'jam_tenggat': jamTenggatController.text,
        'jumlah_alat': widget.cartItems.length,
        'status': 'menunggu', // Status otomatis menunggu
        'created_at': DateTime.now().toIso8601String(),
      });

      // Pindah ke halaman status setelah berhasil
      Get.offAllNamed('/status_tunggu'); 
      Get.snackbar("Berhasil", "Permintaan terkirim, mohon tunggu persetujuan.");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1F3C58);
    // Mengambil nama user yang sedang login
    final String userName = c.supabase.auth.currentUser?.userMetadata?['nama'] ?? "Memuat...";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Pengajuan", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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
            // CARD LIST ALAT
            const Text("Alat yang dipinjam", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
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
                        child: Image.network(item['gambar_url'] ?? "", width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama_alat'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(item['nama_kategori'] ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Text("1 unit", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                );
              },
            ),

            // TOMBOL TAMBAH ALAT
            TextButton.icon(
              onPressed: () => Get.back(), // Kembali ke halaman Beranda (daftar alat)
              icon: const Icon(Icons.add, color: primaryColor),
              label: const Text("tambah alat", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),

            const Divider(height: 30),

            // DETAIL INFO
            _infoRow("Nama", userName),
            _infoRow("Jumlah", "${widget.cartItems.length} unit"),

            const SizedBox(height: 20),

            // INPUT PENGAMBILAN
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

            // INPUT TENGGAT
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

            // TOMBOL AJUKAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _ajukanPeminjaman,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Ajukan peminjaman", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET KECIL UNTUK INFO ROW
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

  // WIDGET KECIL UNTUK INPUT DATE/TIME
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