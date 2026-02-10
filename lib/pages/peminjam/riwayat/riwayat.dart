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

  // Mengambil ID User yang sedang login secara dinamis
  String get currentUserId => c.supabase.auth.currentUser?.id ?? "";

  // 1. Fungsi mengambil Nama dari tabel 'users'
  Future<String> _getNamaPeminjam(String userId) async {
    try {
      final response = await c.supabase
          .from('users')
          .select('nama')
          .eq('id_user', userId)
          .maybeSingle();
      return response != null ? response['nama'] : "User Tidak Dikenal";
    } catch (e) {
      return "Error User";
    }
  }

  // 2. Fungsi menjumlahkan alat dari tabel 'detail_peminjaman'
  Future<int> _getTotalAlat(int idPinjam) async {
    try {
      final response = await c.supabase
          .from('detail_peminjaman')
          .select('jumlah')
          .eq('id_pinjam', idPinjam);
      
      if (response == null) return 0;
      
      int total = 0;
      for (var item in response) {
        total += (item['jumlah'] as int);
      }
      return total;
    } catch (e) {
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
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchTerm = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari riwayat peminjaman . . .",
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

          // LIST RIWAYAT MILIK USER SENDIRI
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase
                  .from('peminjaman')
                  .stream(primaryKey: ['id_pinjam'])
                  .eq('status_transaksi', 'selesai')
                  .eq('id_peminjam', currentUserId) // FILTER: Hanya data user ini
                  .order('pengembalian', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final listPeminjaman = snapshot.data!;

                if (listPeminjaman.isEmpty) {
                  return const Center(child: Text("Anda belum memiliki riwayat selesai"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: listPeminjaman.length,
                  itemBuilder: (context, index) {
                    final item = listPeminjaman[index];
                    final idPinjam = item['id_pinjam'];
                    final idUser = item['id_peminjam'].toString();

                    return FutureBuilder(
                      future: Future.wait([
                        _getNamaPeminjam(idUser),
                        _getTotalAlat(idPinjam),
                      ]),
                      builder: (context, AsyncSnapshot<List<dynamic>> subSnapshot) {
                        String nama = "Memuat...";
                        int totalAlat = 0;

                        if (subSnapshot.hasData) {
                          nama = subSnapshot.data![0];
                          totalAlat = subSnapshot.data![1];
                        }

                        // Filter Pencarian di sisi aplikasi
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

  // WIDGET KARTU RIWAYAT
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
}