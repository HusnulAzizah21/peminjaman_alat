import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/app_controller.dart';
import '../drawer.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final Color primaryColor = const Color(0xFF1F3C58);
  final c = Get.find<AppController>();

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";

  // ID user yang sedang login
  String get currentUserId => c.supabase.auth.currentUser?.id ?? "";

  // Ambil nama peminjam
  Future<String> _getNamaPeminjam(String userId) async {
    try {
      final response = await c.supabase
          .from('users')
          .select('nama')
          .eq('id_user', userId)
          .maybeSingle();
      return response?['nama'] as String? ?? "User Tidak Dikenal";
    } catch (e) {
      debugPrint('Error ambil nama: $e');
      return "Error User";
    }
  }

  // Hitung total jumlah alat
  Future<int> _getTotalAlat(int idPinjam) async {
    try {
      final response = await c.supabase
          .from('detail_peminjaman')
          .select('jumlah')
          .eq('id_pinjam', idPinjam);

      if (response.isEmpty) return 0;

      int total = 0;
      for (var item in response) {
        total += (item['jumlah'] as int? ?? 0);
      }
      return total;
    } catch (e) {
      debugPrint('Error hitung total alat: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Riwayat Saya",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const PeminjamDrawer(currentPage: 'Riwayat'),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchTerm = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari riwayat peminjaman...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
              ),
            ),
          ),

          // Daftar riwayat
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Stream tanpa filter → filter manual di builder
              stream: c.supabase
                  .from('peminjaman')
                  .stream(primaryKey: ['id_pinjam'])
                  .order('pengembalian', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // FILTER MANUAL: hanya riwayat milik user login + status selesai
                final filtered = snapshot.data!.where((item) {
                  return item['status_transaksi'] == 'selesai' &&
                         item['id_peminjam'] == currentUserId;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Belum ada riwayat peminjaman yang selesai",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final idPinjam = item['id_pinjam'] as int;
                    final idUser = item['id_peminjam'] as String;

                    return FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        _getNamaPeminjam(idUser),
                        _getTotalAlat(idPinjam),
                      ]),
                      builder: (context, AsyncSnapshot<List<dynamic>> subSnapshot) {
                        String nama = "Memuat...";
                        int totalAlat = 0;

                        if (subSnapshot.hasData) {
                          nama = subSnapshot.data![0] as String;
                          totalAlat = subSnapshot.data![1] as int;
                        }

                        // Filter pencarian lokal
                        if (_searchTerm.isNotEmpty && !nama.toLowerCase().contains(_searchTerm)) {
                          return const SizedBox.shrink();
                        }

                        String tglKembali = "-";
                        if (item['pengembalian'] != null) {
                          DateTime dt = DateTime.parse(item['pengembalian']).toLocal();
                          tglKembali = DateFormat('dd/MM/yyyy | HH:mm').format(dt);
                        }

                        return _buildRiwayatCard(nama, "$totalAlat alat", tglKembali);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget kartu riwayat (tetap sama seperti desain awal)
  Widget _buildRiwayatCard(String nama, String jumlah, String waktu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 3, height: 35, color: primaryColor),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Riwayat pinjaman $jumlah",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF587D92),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  "Selesai",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Dikembalikan: $waktu",
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}