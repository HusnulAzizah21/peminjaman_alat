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
              const Text("Hapus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
              const SizedBox(height: 10),
              Text("Anda yakin ingin menghapus $name?", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF1F3C58))),
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
                        await c.supabase.from('alat').delete().eq('id_alat', id);
                        Get.back();
                        setState(() {}); 
                        Get.snackbar("Sukses", "Alat berhasil dihapus", backgroundColor: Colors.white);
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
          
          // --- KATEGORI HORIZONTAL ---
          Obx(() {
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

                return SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: dynamicCategories.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedCategory == dynamicCategories[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: InkWell(
                          onTap: () => setState(() => selectedCategory = dynamicCategories[index]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1F3C58) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF1F3C58).withOpacity(0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              dynamicCategories[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1F3C58),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }),
          // --- GRID ALAT ---
          Expanded(
            child: Obx(() {
              // TAMBAHKAN BARIS INI: 
              // Ini akan memicu StreamBuilder untuk membangun ulang UI 
              // setiap kali c.triggerRefresh() dipanggil di halaman Kategori.
              c.refreshKategori.value; 

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: c.supabase.from('daftar_alat_lengkap').stream(primaryKey: ['id']),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Koneksi terputus..."));
                  
                  // MENGHAPUS LOADING MUTER-MUTER (CircularProgressIndicator)
                  // Sesuai permintaan Anda, kita tampilkan SizedBox kosong saat loading awal
                  if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                  
                  final data = snapshot.data ?? [];
                  final filteredItems = data.where((item) {
                    final String nama = (item['nama_alat'] ?? "").toString().toLowerCase();
                    final String katDb = (item['nama_kategori'] ?? "Tanpa Kategori").toString().trim().toLowerCase();
                    bool matchesSearch = nama.contains(searchQuery.toLowerCase());
                    bool matchesCategory = selectedCategory == "Semua" || katDb == selectedCategory.toLowerCase();
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredItems.isEmpty) return const Center(child: Text("Tidak ada alat ditemukan"));

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
              );
            }),
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
            height: 60, width: 60,
            decoration: const BoxDecoration(color: Color(0xFF1F3C58), shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 35),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'alat', child: Text("Tambah Alat", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.w600))),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'kategori', child: Text("Tambah Kategori", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.w600))),
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: (item['gambar_url'] ?? "").toString().isNotEmpty
                  ? Image.network(item['gambar_url'], fit: BoxFit.contain)
                  : const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(item['nama_alat'] ?? "Tanpa Nama", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            // PopupMenu yang sudah disamakan desainnya
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF1F3C58)),
              offset: const Offset(-10, 25),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) async {
                if (value == 'edit') {
                  final res = await Get.to(() => EditAlatPage(alat: item));
                  if (res == true) setState(() {});
                } else if (value == 'hapus') {
                  _confirmDelete(item['id_alat'], item['nama_alat']);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text("Edit", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.w600)),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'hapus',
                  child: Text("Hapus", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        Text(kategori, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(isKosong ? "Kosong" : "$stok unit", style: TextStyle(color: isKosong ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}