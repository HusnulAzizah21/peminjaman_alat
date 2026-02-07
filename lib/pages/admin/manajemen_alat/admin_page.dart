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
      _fetchDynamicCategories();
    } catch (e) {
      debugPrint("Error finding AppController: $e");
    }
  }

  Future<void> _fetchDynamicCategories() async {
    try {
      final response = await c.supabase.from('kategori').select('nama_kategori');
      if (response != null) {
        List<String> fetchedCats = (response as List)
            .map((item) => item['nama_kategori'].toString())
            .toList();
        setState(() {
          dynamicCategories = ["Semua", ...fetchedCats];
        });
      }
    } catch (e) {
      debugPrint("Gagal fetch kategori: $e");
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
              const Text("Anda yakin ingin menghapusnya?", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1F3C58))),
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
                      await c.supabase.from('alat').delete().eq('id_alat', id);
                      Get.back();
                      Get.snackbar("Sukses", "Alat berhasil dihapus", backgroundColor: Colors.white);
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
          
          SizedBox(
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
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('daftar_alat_lengkap').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final data = snapshot.data ?? [];
                final filteredItems = data.where((item) {
                  final String nama = (item['nama_alat'] ?? "").toString().toLowerCase();
                  final String katDb = (item['nama_kategori'] ?? "").toString().trim().toLowerCase();
                  return nama.contains(searchQuery.toLowerCase()) && (selectedCategory == "Semua" || katDb == selectedCategory.toLowerCase());
                }).toList();

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
        padding: const EdgeInsets.only(bottom: 70.0), // Sesuaikan angka ini (misal: 20 atau 30) untuk menaikkan tombol
        child: PopupMenuButton<String>(
          offset: const Offset(0, -110),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (value) async {
            if (value == 'alat') {
              final result = await Get.to(() => const TambahAlatPage());
              if (result == true) setState(() {});
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
                          final res = await Get.to(() => EditAlatPage(alat: item));
                          if (res == true) setState(() {});
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
                          _confirmDelete(item['id'], item['nama_alat']);
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
        Text(item['nama_kategori'] ?? "Kategori", style: const TextStyle(color: Colors.grey, fontSize: 10)),
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