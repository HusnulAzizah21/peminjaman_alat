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

  Future<void> _addKategori() async {
    if (katController.text.isEmpty) return;
    try {
      await c.supabase.from('kategori').insert({'nama_kategori': katController.text});
      katController.clear();
      setState(() {}); 
      Get.snackbar("Sukses", "Kategori ditambahkan");
    } catch (e) {
      Get.snackbar("Error", "Gagal: $e");
    }
  }

  Future<void> _deleteKategori(int id) async {
    try {
      await c.supabase.from('kategori').delete().eq('id', id);
      setState(() {});
      Get.snackbar("Sukses", "Kategori dihapus");
    } catch (e) {
      Get.snackbar("Gagal", "Kategori masih digunakan oleh alat lain");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Kelola Kategori"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F3C58),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: katController,
                    decoration: InputDecoration(
                      hintText: "Nama Kategori Baru",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _addKategori,
                  icon: const Icon(Icons.add_circle, color: Color(0xFF1F3C58), size: 40),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder(
              future: c.supabase.from('kategori').select().order('nama_kategori'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data as List;
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(data[i]['nama_kategori']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteKategori(data[i]['id']),
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