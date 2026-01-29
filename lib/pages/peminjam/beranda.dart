import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import 'peminjaman.dart';
import 'riwayat.dart';

class PeminjamPage extends StatefulWidget {
  const PeminjamPage({super.key});

  @override
  State<PeminjamPage> createState() => _PeminjamPageState();
}

class _PeminjamPageState extends State<PeminjamPage> {
  final c = Get.find<AppController>();
  String searchQuery = "";
  String selectedCategory = "Semua";

  // List kategori sesuai dengan label di tombol filter
  final List<String> categories = ["Semua", "Elektronika", "Alat Musik", "Olahraga"];

  @override
  Widget build(BuildContext context) {
    final user = c.supabase.auth.currentUser;
    final String userEmail = user?.email ?? "User@gmail.com";
    final String userName = userEmail.split('@')[0].capitalizeFirst ?? "User";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.sort, color: Color(0xFF1F3C58)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Beranda",
          style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF1F3C58)),
            onPressed: () {
              // Navigasi ke halaman notifikasi sederhana
              Get.to(() => Scaffold(
                    appBar: AppBar(
                      title: const Text("Notifikasi"),
                      backgroundColor: const Color(0xFF1F3C58),
                    ),
                    body: const Center(child: Text("Tidak ada notifikasi baru")),
                  ));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // HEADER PROFILE
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
              width: double.infinity,
              color: const Color(0xFF1F3C58),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/avatar.png'),
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // MENU ITEMS
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 10),
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: "Beranda",
                    isActive: true,
                    onTap: () => Get.back(),
                  ),
                  _buildMenuItem(
                    icon: Icons.add_box_outlined,
                    title: "Peminjaman",
                    onTap: () {
                      Get.back();
                      Get.to(() => const PeminjamanPage());
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: "Riwayat",
                    onTap: () {
                      Get.back();
                      Get.to(() => const RiwayatPage());
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: "Keluar",
                    onTap: () => c.logout(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Pencarian . . .",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF1F3C58)),
                ),
              ),
            ),
          ),

          // 2. FILTER KATEGORI
          SizedBox(
            height: 40,
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
                        color: isSelected ? const Color(0xFF1F3C58) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1F3C58)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1F3C58),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. GRID ALAT (Mengambil data dari Supabase)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('alat').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data alat."));
                }

                // LOGIKA FILTER: Menggunakan data 'kategori' dari database
                final filteredItems = snapshot.data!.where((item) {
                  final String namaAlat = item['nama_alat'].toString().toLowerCase();
                  final String kategoriDb = item['kategori_id'].toString(); // Mengambil data kolom kategori

                  final matchesSearch = namaAlat.contains(searchQuery.toLowerCase());
                  
                  // Mencocokkan kolom 'kategori' di DB dengan 'selectedCategory' di UI
                  final matchesCategory = selectedCategory == "Semua" || 
                                          kategoriDb == selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    
                    final String namaAlat = item['nama_alat'] ?? "";
                    final int stok = item['stok_total'] ?? 0;
                    final String status = item['status_ketersediaan'] ?? "Kosong";
                    final String imageUrl = item['gambar_url'] ?? "";

                    final Color statusColor = (status.toLowerCase() == 'tersedia') 
                        ? Colors.green 
                        : Colors.red;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GAMBAR ALAT
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, fit: BoxFit.contain)
                                  : const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // INFORMASI ALAT (Kategori tidak ditampilkan sesuai gambar)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    namaAlat,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F3C58),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Stok : $stok unit",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle, color: Color(0xFF1F3C58), size: 20),
                          ],
                        ),
                      ],
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

  // Widget menu item Drawer
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.grey[200] : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1F3C58)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1F3C58),
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}