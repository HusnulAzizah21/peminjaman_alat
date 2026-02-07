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

  // --- LOGIKA BATAL / RESET ---
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
    if (namaBaru.isEmpty) return;
    
    try {
      if (_isEditing && _selectedKategoriId != null) {
        await c.supabase
            .from('kategori')
            .update({'nama_kategori': namaBaru})
            .eq('id_kategori', _selectedKategoriId!);
      } else {
        await c.supabase
            .from('kategori')
            .insert({'nama_kategori': namaBaru});
      }
      
      c.triggerRefresh(); 
      _resetMode();
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan data", backgroundColor: Colors.red, colorText: Colors.white);
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
          leading: IconButton(icon: Icon(Icons.arrow_back, color: primaryColor), onPressed: () => Get.back()),
          title: Text("Tambah Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18)),
          backgroundColor: Colors.white,
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
                    // PENGGANTI LOADING: Jika data belum siap, tampilkan Container kosong atau daftar kosong
                    if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink(); // Tidak ada loading muter-muter
                    }
                    
                    final data = snapshot.data as List? ?? [];
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final item = data[i];
                        bool isRowEditing = _isEditing && _selectedKategoriId == item['id_kategori'];

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: isRowEditing 
                                ? TextField(
                                    controller: editController,
                                    autofocus: true,
                                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                  )
                                : InkWell(
                                    onTap: () => _startInlineEdit(item['id_kategori'], item['nama_kategori']),
                                    child: Text(item['nama_kategori'], 
                                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
                                  ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isRowEditing) ...[
                                    IconButton(
                                      icon: Icon(Icons.check, color: primaryColor, size: 20),
                                      onPressed: () => _simpanKategori(isInline: true),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.cancel, color: primaryColor, size: 20),
                                      onPressed: _resetMode,
                                    ),
                                  ],
                                  if (!isRowEditing)
                                    IconButton(
                                      icon: Icon(Icons.delete, color: primaryColor, size: 20),
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
              TextField(
                controller: katController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Masukkan nama kategori",
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                  ),
                  child: const Text("Tambah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
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
              const Text("Hapus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
              const SizedBox(height: 10),
              Text("Hapus kategori '$name'?", textAlign: TextAlign.center),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(onPressed: () => Get.back(), child: const Text("Batal")),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await c.supabase.from('kategori').delete().eq('id_kategori', id);
                        c.triggerRefresh(); 
                        Get.back();
                        _resetMode(); 
                      } catch (e) {
                        Get.back();
                        Get.snackbar("Gagal", "Data masih digunakan", backgroundColor: Colors.red, colorText: Colors.white);
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
}