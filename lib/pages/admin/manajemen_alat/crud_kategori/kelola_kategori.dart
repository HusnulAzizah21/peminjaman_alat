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

  bool _isEditing = false;
  int? _selectedKategoriId;

  void _resetMode() {
    setState(() {
      _isEditing = false;
      _selectedKategoriId = null;
      katController.clear();
      editController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  void _startInlineEdit(int id, String currentName) {
    setState(() {
      _isEditing = true;
      _selectedKategoriId = id;
      editController.text = currentName;
    });
  }

  Future<void> _simpanKategori({bool isInline = false}) async {
    String namaBaru = isInline ? editController.text : katController.text;
    if (namaBaru.trim().isEmpty) return;

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

      // AUTO REFRESH LOKAL
      setState(() {}); 
      _resetMode();
      
      if (!isInline) {
        Get.snackbar("Sukses", "Kategori berhasil disimpan",
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isEditing) _resetMode();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryColor),
              onPressed: () => Get.back(result: true)), // Mengirim result true untuk refresh admin page
          title: Text("Kelola Kategori",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: c.supabase
                      .from('kategori')
                      .stream(primaryKey: ['id_kategori']).order('nama_kategori'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Belum ada kategori"));
                    }

                    final data = snapshot.data!;
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final item = data[i];
                        bool isRowEditing = _isEditing &&
                            _selectedKategoriId == item['id_kategori'];

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: isRowEditing
                                  ? TextField(
                                      controller: editController,
                                      autofocus: true,
                                      style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                      decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true),
                                      onSubmitted: (_) =>
                                          _simpanKategori(isInline: true),
                                    )
                                  : InkWell(
                                      onLongPress: () => _startInlineEdit(
                                          item['id_kategori'],
                                          item['nama_kategori']),
                                      child: Text(item['nama_kategori'],
                                          style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isRowEditing) ...[
                                    IconButton(
                                      icon: const Icon(Icons.check,
                                          color: Colors.green, size: 20),
                                      onPressed: () =>
                                          _simpanKategori(isInline: true),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.red, size: 20),
                                      onPressed: _resetMode,
                                    ),
                                  ] else ...[
                                    IconButton(
                                      icon: Icon(Icons.edit_note,
                                          color: primaryColor, size: 20),
                                      onPressed: () => _startInlineEdit(
                                          item['id_kategori'],
                                          item['nama_kategori']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      onPressed: () => _confirmDeleteKategori(
                                          item['id_kategori'],
                                          item['nama_kategori']),
                                    ),
                                  ],
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
              TextField(
                controller: katController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Masukkan nama kategori baru",
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => _simpanKategori(isInline: false),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  child: const Text("Tambah Kategori",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteKategori(int id, String name) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Hapus Kategori",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F3C58))),
              const SizedBox(height: 10),
              Text("Anda yakin ingin menghapus '$name'?",
                  textAlign: TextAlign.center),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () => Get.back(), child: const Text("Batal")),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await c.supabase
                            .from('kategori')
                            .delete()
                            .eq('id_kategori', id);
                        
                        setState(() {}); // AUTO REFRESH SETELAH HAPUS
                        Get.back();
                        Get.snackbar("Terhapus", "Kategori berhasil dihapus",
                            backgroundColor: Colors.orange);
                      } catch (e) {
                        Get.back();
                        Get.snackbar("Gagal", "Kategori ini masih digunakan oleh data alat",
                            backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child:
                        const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}