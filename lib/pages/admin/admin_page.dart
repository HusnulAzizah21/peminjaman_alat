import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import 'drawer.dart';
// Import file baru yang akan dibuat (pastikan path benar)
import 'crud_alat/form_alat.dart'; 
import 'crud_kategori/kelola_kategori.dart';

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

  final List<String> categories = ["Semua", "Elektronik", "Alat Musik", "Olahraga"];

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

  // --- KODE BARU: FUNGSI PILIHAN EDIT/HAPUS ---
  void _showEditDeleteOptions(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("Edit Alat"),
            onTap: () {
              Get.back();
              Get.to(() => FormAlatPage(alat: item)); // Navigasi ke Form Edit
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Hapus Alat"),
            onTap: () {
              Get.back();
              _confirmDelete(item['id'], item['nama_alat']);
            },
          ),
        ],
      ),
    );
  }

  // --- KODE BARU: KONFIRMASI HAPUS ---
  void _confirmDelete(dynamic id, String name) {
    Get.defaultDialog(
      title: "Hapus Alat",
      middleText: "Apakah Anda yakin ingin menghapus $name?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        await c.supabase.from('alat').delete().eq('id', id);
        Get.back();
        Get.snackbar("Sukses", "Alat berhasil dihapus", backgroundColor: Colors.white);
      },
    );
  }

  // --- KODE BARU: PILIHAN TOMBOL TAMBAH (+) ---
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Color(0xFF1F3C58)),
              title: const Text("Tambah Alat Baru"),
              onTap: () {
                Get.back();
                Get.to(() => const FormAlatPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.category, color: Color(0xFF1F3C58)),
              title: const Text("Kelola Kategori"),
              onTap: () {
                Get.back();
                Get.to(() => const KelolaKategoriPage());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1F3C58)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Manajemen Alat",
          style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold),
        ),
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
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1F3C58) : Colors.grey.shade300,
                        ),
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
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('daftar_alat_lengkap').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) return const Center(child: Text("Tidak ada data alat."));

                final filteredItems = data.where((item) {
                  final String nama = (item['nama_alat'] ?? "").toString().toLowerCase();
                  final String katDb = (item['nama_kategori'] ?? "").toString().trim().toLowerCase();
                  final String katSelected = selectedCategory.trim().toLowerCase();
                  final matchesSearch = nama.contains(searchQuery.toLowerCase());
                  bool matchesCat = selectedCategory == "Semua" || katDb == katSelected;
                  return matchesSearch && matchesCat;
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 25,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildAdminToolCard(context, item); // Pass context & item
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context), // Update: Panggil pilihan (+)
        backgroundColor: const Color(0xFF1F3C58),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // UPDATE: Widget Card menerima data item untuk kebutuhan edit/hapus
  Widget _buildAdminToolCard(BuildContext context, Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: (item['gambar_url'] ?? "").toString().isNotEmpty
                  ? Image.network(
                      item['gambar_url'],
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.image_not_supported),
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
            // Update: Ikon titik tiga sekarang bisa diklik
            IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, color: Color(0xFF1F3C58), size: 18),
              onPressed: () => _showEditDeleteOptions(context, item),
            ),
          ],
        ),
        Text(item['nama_kategori'] ?? "Umum", style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(
          "${item['stok_total'] ?? 0} unit",
          style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}