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

  String get currentUserId => c.userProfile['id_user']?.toString() ?? "";

  Future<String> _getNamaPeminjam(String userId) async {
    try {
      final response = await c.supabase
          .from('users')
          .select('nama')
          .eq('id_user', userId)
          .maybeSingle();
      return response?['nama'] as String? ?? "User Tidak Dikenal";
    } catch (e) {
      return "Error User";
    }
  }

  Future<int> _getTotalAlat(int idPinjam) async {
    try {
      final response = await c.supabase
          .from('detail_peminjaman')
          .select('jumlah')
          .eq('id_pinjam', idPinjam);

      if (response == null) return 0;
      int total = 0;
      for (var item in response) {
        total += (item['jumlah'] as int? ?? 0);
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
        title: Text("Riwayat Saya", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // PERBAIKAN: Filter dilakukan di dalam .map() karena .stream() tidak mendukung .eq()
              stream: c.supabase
                  .from('peminjaman')
                  .stream(primaryKey: ['id_pinjam'])
                  .map((data) => data
                      .where((item) => 
                          item['id_peminjam'] == currentUserId && 
                          item['status_transaksi'] == 'selesai')
                      .toList()
                    ..sort((a, b) {
                      // Manual sorting karena .order() juga tidak bisa setelah .stream()
                      final dateA = a['pengembalian'] ?? '';
                      final dateB = b['pengembalian'] ?? '';
                      return dateB.compareTo(dateA);
                    })),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final data = snapshot.data ?? [];
                if (data.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        _getNamaPeminjam(currentUserId),
                        _getTotalAlat(item['id_pinjam']),
                      ]),
                      builder: (context, AsyncSnapshot<List<dynamic>> subSnapshot) {
                        String nama = subSnapshot.hasData ? subSnapshot.data![0] : "Memuat...";
                        int totalAlat = subSnapshot.hasData ? subSnapshot.data![1] : 0;

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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchTerm = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Cari riwayat...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
          Text("Belum ada riwayat peminjaman yang selesai"),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(String nama, String jumlah, String waktu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Badge(label: Text("Selesai"), backgroundColor: Color(0xFF587D92)),
            ],
          ),
          Text("Riwayat pinjaman $jumlah", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(),
          Text("Dikembalikan: $waktu", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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