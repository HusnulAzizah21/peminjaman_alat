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
  final editController = TextEditingController();
  final Color primaryColor = const Color(0xFF1F3C58);

  // State Management
  bool _isEditing = false;
  bool _isLoading = false;
  int? _selectedKategoriId;

  // 1. Simpan stream ke dalam variabel agar tidak dibuat ulang setiap build
  late Stream<List<Map<String, dynamic>>> _kategoriStream;

  @override
  void initState() {
    super.initState();
    // Inisialisasi stream hanya sekali saat halaman dibuka
    _kategoriStream = c.supabase
        .from('kategori')
        .stream(primaryKey: ['id_kategori'])
        .order('nama_kategori');
  }

  void _resetMode() {
    setState(() {
      _isEditing = false;
      _selectedKategoriId = null;
      katController.clear();
      editController.clear();
      _isLoading = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _startInlineEdit(int id, String currentName) {
    // Pastikan tidak ada loading saat mulai edit
    setState(() {
      _isEditing = true;
      _selectedKategoriId = id;
      editController.text = currentName;
    });
  }

  Future<void> _simpanKategori({bool isInline = false}) async {
    String namaBaru = isInline ? editController.text : katController.text;
    if (namaBaru.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing && _selectedKategoriId != null && isInline) {
        await c.supabase
            .from('kategori')
            .update({'nama_kategori': namaBaru.trim()})
            .eq('id_kategori', _selectedKategoriId!);
      } else {
        await c.supabase
            .from('kategori')
            .insert({'nama_kategori': namaBaru.trim()});
      }
      
      _resetMode(); 
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Gagal: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { if (_isEditing) _resetMode(); },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Kelola Kategori", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1F3C58)), onPressed: () => Get.back()),
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _kategoriStream, // Pakai variabel stream yang sudah tetap
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data ?? [];
                        return ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, i) {
                            final item = data[i];
                            bool isRowEditing = _isEditing && _selectedKategoriId == item['id_kategori'];

                            return ListTile(
                              title: isRowEditing
                                  ? TextField(
                                      controller: editController,
                                      autofocus: true,
                                      onSubmitted: (_) => _simpanKategori(isInline: true),
                                    )
                                  : Text(item['nama_kategori']),
                              trailing: _buildActions(item, isRowEditing),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildInputField(),
                ],
              ),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  // Pisahkan widget tombol aksi agar build lebih ringan
  Widget _buildActions(Map<String, dynamic> item, bool isEditing) {
    if (isEditing) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _simpanKategori(isInline: true)),
        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: _resetMode),
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.edit_note), onPressed: () => _startInlineEdit(item['id_kategori'], item['nama_kategori'])),
      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(item['id_kategori'])),
    ]);
  }

  Widget _buildInputField() {
    return Column(children: [
      TextField(controller: katController, decoration: const InputDecoration(hintText: "Tambah Kategori Baru")),
      const SizedBox(height: 10),
      ElevatedButton(onPressed: _isLoading ? null : () => _simpanKategori(), child: const Text("Simpan")),
      const SizedBox(height: 20),
    ]);
  }

  void _confirmDelete(int id) async {
     // Gunakan Get.defaultDialog agar lebih ringkas
     Get.defaultDialog(
       title: "Hapus?",
       middleText: "Data akan hilang permanen",
       onConfirm: () async {
         Get.back();
         setState(() => _isLoading = true);
         await c.supabase.from('kategori').delete().eq('id_kategori', id);
         setState(() => _isLoading = false);
       }
     );
  }
}