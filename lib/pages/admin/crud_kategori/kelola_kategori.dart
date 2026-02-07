import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';

class KelolaKategoriPage extends StatefulWidget {
  const KelolaKategoriPage({super.key});

  @override
  State<KelolaKategoriPage> createState() => _KelolaKategoriPageState();
}

class _KelolaKategoriPageState extends State<KelolaKategoriPage> {
  final c = Get.find<AppController>();
  final katController = TextEditingController();

  // Fungsi Tambah
  Future<void> _addKategori() async {
    if (katController.text.isEmpty) return;
    try {
      await c.supabase.from('kategori').insert({'nama_kategori': katController.text});
      katController.clear();
      c.triggerRefresh(); // Beritahu halaman lain untuk refresh
      setState(() {}); 
      Get.snackbar("Sukses", "Kategori ditambahkan");
    } catch (e) {
      Get.snackbar("Error", "Gagal: $e");
    }
  }

  // Fungsi Edit
  Future<void> _editKategori(int id, String namaLama) async {
    final editController = TextEditingController(text: namaLama);
    Get.defaultDialog(
      title: "Edit Kategori",
      content: TextField(controller: editController),
      textConfirm: "Simpan",
      onConfirm: () async {
        await c.supabase.from('kategori').update({'nama_kategori': editController.text}).eq('id_kategori', id);
        c.triggerRefresh();
        setState(() {});
        Get.back();
      }
    );
  }

  // Fungsi Hapus (Set Alat menjadi Null/Tanpa Kategori)
  Future<void> _deleteKategori(int id) async {
    try {
      // 1. Update alat yang pakai kategori ini agar jadi null (Tidak ada kategori)
      await c.supabase.from('alat').update({'id_kategori': null}).eq('id_kategori', id);
      
      // 2. Baru hapus kategorinya
      await c.supabase.from('kategori').delete().eq('id_kategori', id);
      
      c.triggerRefresh();
      setState(() {});
      Get.snackbar("Sukses", "Kategori dihapus");
    } catch (e) {
      Get.snackbar("Gagal", "Kesalahan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (AppBar tetap sama)
      body: Column(
        children: [
          // ... (Input TextField tetap sama)
          Expanded(
            child: FutureBuilder(
              // Gunakan Obx atau pemicu refresh
              future: c.supabase.from('kategori').select().order('nama_kategori'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data as List;
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(data[i]['nama_kategori']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editKategori(data[i]['id_kategori'], data[i]['nama_kategori']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteKategori(data[i]['id_kategori']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}