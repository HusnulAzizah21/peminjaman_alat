import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';
import '../drawer.dart';
import 'crud_alat/edit_alat.dart'; 
import 'crud_kategori/kelola_kategori.dart';
import 'crud_alat/tambah_alat.dart'; 

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminBerandaPageState();
}

class _AdminBerandaPageState extends State<AdminPage> {
  late AppController c;
  String searchQuery = "";
  String selectedCategory = "Semua";
  bool isInitialized = false;
  List<String> dynamicCategories = ["Semua"];

  @override
  void initState() {
    super.initState();
    try {
      c = Get.find<AppController>();
      isInitialized = true;
    } catch (e) {
      debugPrint("Error finding AppController: $e");
    }
  }

void _confirmDelete(dynamic id, String name) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Hapus", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
              const SizedBox(height: 10),
              Text("Anda yakin ingin menghapus $name?", 
                textAlign: TextAlign.center, 
                style: const TextStyle(color: Color(0xFF1F3C58))),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1F3C58)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                    ),
                    child: const Text("Batal", style: TextStyle(color: Color(0xFF1F3C58))),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // 1. Jalankan proses hapus di Supabase
                        await c.supabase.from('alat').delete().eq('id_alat', id);
                        
                        // 2. Tutup Dialog
                        Get.back();

                        // 3. Autorefresh: Karena Anda menggunakan StreamBuilder, 
                        // kita picu rebuild UI dengan setState kosong jika diperlukan, 
                        // atau biarkan StreamBuilder yang menangani secara otomatis.
                        setState(() {}); 

                        Get.snackbar(
                          "Sukses", 
                          "Alat berhasil dihapus", 
                          backgroundColor: const Color(0xFF1F3C58),
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM
                        );
                      } catch (e) {
                        Get.back();
                        Get.snackbar("Error", "Gagal menghapus: $e", backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F3C58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                    ),
                    child: const Text("Ya", style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1F3C58)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text("Manajemen Alat", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
      ),
      drawer: const AdminDrawer(currentPage: 'Manajemen Alat'),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Pencarian . . .",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1F3C58)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF1F3C58)),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
          
          // --- KATEGORI HORIZONTAL (AUTO REFRESH) ---
Obx(() {
  // Baris ini memantau perubahan dari KelolaKategoriPage
  c.refreshKategori.value; 

  return FutureBuilder(
    future: c.supabase.from('kategori').select('nama_kategori').order('nama_kategori'),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        List<String> fetchedCats = (snapshot.data as List)
            .map((item) => item['nama_kategori'].toString())
            .toList();
        dynamicCategories = ["Semua", ...fetchedCats];
      }
      // ... return ListView.builder Kategori Horizontal Anda ...
      return SizedBox(
        height: 45,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: dynamicCategories.length,
          itemBuilder: (context, index) {
            // ... kode UI kategori Anda ...
          }
        ),
      );
    },
  );
}),

          // --- GRID ALAT (STREAM) ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Menggunakan stream agar alat yang berubah kategori atau stok langsung update otomatis
              stream: c.supabase.from('daftar_alat_lengkap').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final data = snapshot.data ?? [];
                final filteredItems = data.where((item) {
                  final String nama = (item['nama_alat'] ?? "").toString().toLowerCase();
                  final String katDb = (item['nama_kategori'] ?? "Tanpa Kategori").toString().trim().toLowerCase();
                  
                  bool matchesSearch = nama.contains(searchQuery.toLowerCase());
                  bool matchesCategory = selectedCategory == "Semua" || katDb == selectedCategory.toLowerCase();
                  
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text("Tidak ada alat ditemukan"));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 25,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) => _buildAdminToolCard(context, filteredItems[index]),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0), 
        child: PopupMenuButton<String>(
          offset: const Offset(0, -110),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (value) async {
            if (value == 'alat') {
              Get.to(() => const TambahAlatPage());
            } else if (value == 'kategori') {
              Get.to(() => const KelolaKategoriPage());
            }
          },
          child: Container(
            height: 60,
            width: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF1F3C58),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 35),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'alat',
              child: Text("Tambah Alat",
                  style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.w600)),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'kategori',
              child: Text("Tambah Kategori",
                  style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminToolCard(BuildContext context, Map<String, dynamic> item) {
    int stok = item['stok_total'] ?? 0;
    bool isKosong = stok <= 0;
    String kategori = item['nama_kategori'] ?? "Tanpa Kategori";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: (item['gambar_url'] ?? "").toString().isNotEmpty
                  ? Image.network(item['gambar_url'], fit: BoxFit.contain)
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item['nama_alat'] ?? "Tanpa Nama",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58), fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1F3C58), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              offset: const Offset(-10, 20),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              color: Colors.white,
              itemBuilder: (context) => [
                PopupMenuItem(
                  height: 40,
                  enabled: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          Get.to(() => EditAlatPage(alat: item));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, size: 16, color: Color(0xFF1F3C58)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDelete(item['id_alat'], item['nama_alat']);
                        },
                        child: const Icon(Icons.delete, size: 20, color: Color(0xFF1F3C58)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // Menampilkan kategori (akan "Tanpa Kategori" jika id_kategori di database null)
        Text(kategori, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          isKosong ? "Kosong" : "$stok unit",
          style: TextStyle(
            color: isKosong ? Colors.red : Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}