import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';
import '../drawer.dart';
import 'transaksi_page.dart';

class PeminjamPage extends StatefulWidget {
  const PeminjamPage({super.key});

  @override
  State<PeminjamPage> createState() => _PeminjamPageState();
}

class _PeminjamPageState extends State<PeminjamPage> {
  final c = Get.find<AppController>();
  String searchQuery = "";
  String selectedCategory = "Semua";
  
  // List keranjang sederhana
  List<Map<String, dynamic>> cartItems = [];

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1F3C58);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Beranda",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const PeminjamDrawer(currentPage: 'Beranda'),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Pencarian . . .",
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    contentPadding: EdgeInsets.zero, // Perbaikan error padding
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: primaryColor),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),

              // 2. KATEGORI (Real-time Stream)
              SizedBox(
                height: 45,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: c.supabase.from('kategori').stream(primaryKey: ['id_kategori']),
                  builder: (context, snapshot) {
                    List<String> categories = ["Semua"];
                    if (snapshot.hasData && snapshot.data != null) {
                      categories.addAll(snapshot.data!.map((e) => e['nama_kategori'].toString()).toList());
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
                                color: isSelected ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : primaryColor,
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

              // 3. GRID DAFTAR ALAT (Real-time Stream)
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: c.supabase.from('daftar_alat_lengkap').stream(primaryKey: ['id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Data tidak tersedia"));
                    }

                    final allItems = snapshot.data!;
                    final filteredItems = allItems.where((item) {
                      final nama = (item['nama_alat'] ?? "").toString().toLowerCase();
                      final kat = (item['nama_kategori'] ?? "").toString();
                      return nama.contains(searchQuery.toLowerCase()) && 
                             (selectedCategory == "Semua" || kat == selectedCategory);
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12), // 🔥 shadow lembut
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 6), // bayangan ke bawah
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Center( // ✅ bikin posisi bener-bener tengah
                                    child: FractionallySizedBox(
                                      widthFactor: 0.75,   // 🔽 atur besar kecil gambar
                                      heightFactor: 0.75,
                                      child: (item['gambar_url'] ?? "").toString().isNotEmpty
                                          ? Image.network(
                                              item['gambar_url'],
                                              fit: BoxFit.contain,   // ❌ tidak zoom
                                              alignment: Alignment.center,
                                              filterQuality: FilterQuality.high,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(Icons.broken_image, color: Colors.grey),
                                            )
                                          : const Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(item['nama_alat'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                            Text(item['nama_kategori'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${item['stok_total'] ?? 0} unit", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      cartItems.add(item);
                                    });
                                    Get.snackbar("Sukses", "${item['nama_alat']} ditambah", 
                                      snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
                                  },
                                  child: const Icon(Icons.add_circle, color: primaryColor, size: 24),
                                ),
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

          // 4. TOMBOL KERANJANG (FAB)
          if (cartItems.isNotEmpty)
            Positioned(
              bottom: 30,
              right: 20,
              child: InkWell(
                onTap: () => Get.to(() => TransaksiPage(cartItems: List.from(cartItems))),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Badge(
                    label: Text("${cartItems.length}"),
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.shopping_cart_outlined, color: primaryColor, size: 30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}