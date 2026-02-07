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

  bool _isEditing = false;
  int? _selectedKategoriId;

  // --- RESET MODE ---
  void _resetMode() {
    setState(() {
      _isEditing = false;
      _selectedKategoriId = null;
      katController.clear();
    });
  }

  // --- MODE EDIT ---
  void _setEditMode(int id, String currentName) {
    setState(() {
      _isEditing = true;
      _selectedKategoriId = id;
      katController.text = currentName;
    });
  }

  // --- FUNGSI SIMPAN (TAMBAH & UPDATE) ---
  Future<void> _simpanKategori() async {
    if (katController.text.isEmpty) return;
    
    try {
      if (_isEditing) {
        await c.supabase
            .from('kategori')
            .update({'nama_kategori': katController.text})
            .eq('id_kategori', _selectedKategoriId!);
        
        Get.snackbar("Sukses", "Kategori diperbarui", backgroundColor: Colors.white);
      } else {
        await c.supabase
            .from('kategori')
            .insert({'nama_kategori': katController.text});
        
        Get.snackbar("Sukses", "Kategori ditambahkan", backgroundColor: Colors.white);
      }
      
      // TRIGGER REFRESH: Memberitahu AdminPage untuk update list horizontal
      c.triggerRefresh(); 
      _resetMode();
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // --- DIALOG HAPUS ---
  void _confirmDeleteKategori(int id, String name) {
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
              Text("Hapus kategori '$name'?", textAlign: TextAlign.center),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text("Batal"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await c.supabase.from('kategori').delete().eq('id_kategori', id);
                        
                        c.triggerRefresh(); // Refresh AdminPage
                        Get.back();
                        _resetMode(); // Refresh list lokal
                        Get.snackbar("Sukses", "Kategori dihapus", backgroundColor: Colors.white);
                      } catch (e) {
                        Get.back();
                        Get.snackbar("Gagal", "Kategori masih digunakan alat lain", backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Kategori" : "Tambah Kategori", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: c.supabase.from('kategori').select().order('nama_kategori'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final data = snapshot.data as List? ?? [];
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final item = data[i];
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['nama_kategori'], style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: primaryColor, size: 20),
                                  onPressed: () => _setEditMode(item['id_kategori'], item['nama_kategori']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  onPressed: () => _confirmDeleteKategori(item['id_kategori'], item['nama_kategori']),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1, height: 1),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            if (_isEditing)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _resetMode, child: const Text("Batal Edit", style: TextStyle(color: Colors.red))),
              ),
            TextField(
              controller: katController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Nama kategori",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _simpanKategori,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: Text(_isEditing ? "Simpan Perubahan" : "Tambah", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}