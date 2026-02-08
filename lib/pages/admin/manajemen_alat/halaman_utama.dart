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
                    ),
                    child: const Text("Batal", style: TextStyle(color: Color(0xFF1F3C58))),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await c.supabase.from('alat').delete().eq('id_alat', id);
                        Get.back();
                        setState(() {}); // AUTO REFRESH SETELAH HAPUS ALAT

                        Get.snackbar(
                          "Sukses", 
                          "Alat berhasil dihapus", 
                          backgroundColor: Colors.white,
                          colorText: const Color(0xFF1F3C58)
                        );
                      } catch (e) {
                        Get.back();
                        Get.snackbar(
                          "Error", 
                          "Gagal menghapus: Data mungkin sedang dipinjam", 
                          backgroundColor: Colors.red, 
                          colorText: Colors.white
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F3C58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          
          // --- AUTO REFRESH KATEGORI BAR ---
          SizedBox(
            height: 45,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('kategori').stream(primaryKey: ['id_kategori']).order('nama_kategori'),
              builder: (context, snapshot) {
                List<String> categories = ["Semua"];
                if (snapshot.hasData) {
                  categories.addAll(snapshot.data!.map((e) => e['nama_kategori'].toString()));
                  // Validasi jika kategori terpilih tiba-tiba dihapus
                  if (!categories.contains(selectedCategory)) {
                    Future.delayed(Duration.zero, () => setState(() => selectedCategory = "Semua"));
                  }
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    bool isSelected = selectedCategory == categories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: InkWell(
                        onTap: () => setState(() => selectedCategory = categories[index]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1F3C58) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF1F3C58).withOpacity(0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            categories[index],
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
                );
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('daftar_alat_lengkap').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                if (snapshot.hasError) return const Center(child: Text("Gagal memuat data"));

                final data = snapshot.data ?? [];
                final filteredItems = data.where((item) {
                  final String nama = (item['nama_alat'] ?? "").toString().toLowerCase();
                  final String kat = (item['nama_kategori'] ?? "Tanpa Kategori").toString();
                  bool matchesSearch = nama.contains(searchQuery.toLowerCase());
                  bool matchesCategory = selectedCategory == "Semua" || kat == selectedCategory;
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
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), 
        child: PopupMenuButton<String>(
          offset: const Offset(0, -110),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onSelected: (value) async {
            if (value == 'alat') {
              var reload = await Get.to(() => const TambahAlatPage());
              if (reload == true) setState(() {});
            } else if (value == 'kategori') {
              var reloadKategori = await Get.to(() => const KelolaKategoriPage());
              if (reloadKategori == true) setState(() {}); // AUTO REFRESH SETELAH KELOLA KATEGORI
            }
          },
          child: Container(
            height: 60, width: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF1F3C58), 
              shape: BoxShape.circle, 
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 35),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'alat', 
              child: ListTile(leading: Icon(Icons.inventory), title: Text("Tambah Alat"))
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'kategori', 
              child: ListTile(leading: Icon(Icons.category), title: Text("Kelola Kategori"))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminToolCard(BuildContext context, Map<String, dynamic> item) {
    int stok = item['stok_total'] ?? 0;
    bool isKosong = stok <= 0;
    const primaryColor = Color(0xFF1F3C58);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: (item['gambar_url'] ?? "").toString().isNotEmpty
                  ? Image.network(item['gambar_url'], fit: BoxFit.cover, 
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(item['nama_alat'] ?? "Tanpa Nama", 
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) async {
                if (value == 'edit') {
                  var reload = await Get.to(() => EditAlatPage(alat: item));
                  if (reload == true) setState(() {}); 
                } else if (value == 'hapus') {
                  _confirmDelete(item['id_alat'], item['nama_alat']);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit', 
                  child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Edit")]),
                ),
                const PopupMenuItem(
                  value: 'hapus', 
                  child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: Colors.red))]),
                ),
              ],
            ),
          ],
        ),
        Text(item['nama_kategori'] ?? "Tanpa Kategori", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(isKosong ? "Stok Habis" : "Tersedia: $stok", 
          style: TextStyle(color: isKosong ? Colors.red : Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}