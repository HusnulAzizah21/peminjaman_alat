import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/app_controller.dart';

class KelolaKategoriPage extends StatefulWidget {
  const KelolaKategoriPage({super.key});

  @override
  State<KelolaKategoriPage> createState() => _KelolaKategoriPageState();
}

class _KelolaKategoriPageState extends State<KelolaKategoriPage> {
  final c = Get.find<AppController>();
  final katController = TextEditingController();
  final Color primaryColor = const Color(0xFF1F3C58);

  // --- DIALOG VALIDASI HAPUS ---
  void _confirmDeleteKategori(int id, String name) {
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
              Text("Anda yakin ingin menghapus kategori '$name'?", 
                textAlign: TextAlign.center, 
                style: const TextStyle(color: Color(0xFF1F3C58))),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                    ),
                    child: Text("Batal", style: TextStyle(color: primaryColor)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await c.supabase.from('kategori').delete().eq('id', id);
                        Get.back();
                        setState(() {});
                        Get.snackbar("Sukses", "Kategori dihapus", backgroundColor: Colors.white);
                      } catch (e) {
                        Get.back();
                        Get.snackbar("Gagal", "Kategori masih digunakan", backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
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

  Future<void> _addKategori() async {
    if (katController.text.isEmpty) return;
    try {
      await c.supabase.from('kategori').insert({'nama_kategori': katController.text});
      katController.clear();
      setState(() {});
      Get.snackbar("Sukses", "Kategori berhasil ditambahkan", backgroundColor: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Gagal: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tambah Kategori", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // DAFTAR KATEGORI (List dengan divider seperti di gambar)
            Expanded(
              child: FutureBuilder(
                future: c.supabase.from('kategori').select().order('nama_kategori'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data as List? ?? [];
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) => Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(data[i]['nama_kategori'], 
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: primaryColor, size: 20),
                            onPressed: () => _confirmDeleteKategori(data[i]['id'], data[i]['nama_kategori']),
                          ),
                        ),
                        const Divider(thickness: 1, height: 1),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            // INPUT FIELD (Rounded/Lonjong)
            TextField(
              controller: katController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Masukkan nama kategori",
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            // TOMBOL TAMBAH (Lebar dan Rounded)
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _addKategori,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text("Tambah", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}