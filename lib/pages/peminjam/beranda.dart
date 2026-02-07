import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import 'drawer.dart';

class PeminjamPage extends StatefulWidget {
  const PeminjamPage({super.key});

  @override
  State<PeminjamPage> createState() => _PeminjamPageState();
}

class _PeminjamPageState extends State<PeminjamPage> {
  final c = Get.find<AppController>();
  String searchQuery = "";
  String selectedCategory = "Semua";

  // PERBAIKAN: Nama kategori disesuaikan persis dengan database (Elektronik)
  final List<String> categories = ["Semua", "Elektronik", "Alat Musik", "Olahraga"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // Menghilangkan warna ungu/gelap saat scroll
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1F3C58)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Beranda",
          style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.email_outlined, color: Color(0xFF1F3C58)),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const PeminjamDrawer(currentPage: 'Beranda'),
      body: Column(
        children: [
          // 1. SEARCH BAR
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

          // 2. FILTER KATEGORI (UI Horizontal)
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
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. GRID ALAT (Real-time Stream)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Mengambil dari View 'daftar_alat_lengkap'
              stream: c.supabase.from('daftar_alat_lengkap').stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Tidak ada data alat."));
                }

                // LOGIKA FILTERING: Search & Kategori (Case Insensitive)
                final filteredItems = snapshot.data!.where((item) {
                  final String nama = (item['nama_alat'] ?? "").toString().toLowerCase();
                  final String katDb = (item['nama_kategori'] ?? "").toString().trim().toLowerCase();
                  final String katSelected = selectedCategory.trim().toLowerCase();
                  
                  final matchesSearch = nama.contains(searchQuery.toLowerCase());
                  
                  // Filter kategori: Munculkan semua jika "Semua", atau jika nama kategori cocok
                  bool matchesCat = selectedCategory == "Semua" || katDb == katSelected;
                  
                  return matchesSearch && matchesCat;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text("Barang tidak ditemukan."));
                }

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
                    
                    // Pastikan konversi ke String/Int dilakukan dengan aman (Pencegahan TypeError)
                    final String namaAlat = (item['nama_alat'] ?? "").toString();
                    final String kategori = (item['nama_kategori'] ?? "").toString();
                    final int stok = int.tryParse(item['stok_total']?.toString() ?? '0') ?? 0;
                    final String img = (item['gambar_url'] ?? "").toString();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Container Gambar
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: img.isNotEmpty 
                                ? Image.network(
                                    img, 
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Nama Alat
                        Text(
                          namaAlat, 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Kategori Alat
                        Text(kategori, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        
                        // Baris Stok & Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stok > 0 ? "$stok unit" : "kosong",
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: FontWeight.bold,
                                color: stok > 0 ? Colors.green : Colors.red
                              ),
                            ),
                            const Icon(Icons.add_circle, color: Color(0xFF1F3C58), size: 22),
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
}