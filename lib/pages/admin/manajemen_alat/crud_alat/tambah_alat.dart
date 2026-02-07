import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../controllers/app_controller.dart';

class TambahAlatPage extends StatefulWidget {
  const TambahAlatPage({super.key});

  @override
  State<TambahAlatPage> createState() => _TambahAlatPageState();
}

class _TambahAlatPageState extends State<TambahAlatPage> {
  final c = Get.find<AppController>();
  final _formKey = GlobalKey<FormState>();
  
  final nameController = TextEditingController();
  final stokController = TextEditingController();
  
  String? selectedKategori;
  Uint8List? _imageBytes; 
  String? _fileName;
  bool _isLoading = false;

  // --- AMBIL GAMBAR (UNIVERSAL) ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, 
    );
    
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = image.name;
      });
    }
  }

  // --- SIMPAN OTOMATIS KE BUCKET & DATABASE ---
  Future<void> _saveAlat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 1. OTOMATIS UPLOAD KE BUCKET
      if (_imageBytes != null && _fileName != null) {
        final String fileExt = _fileName!.split('.').last;
        final String path = "alat/${DateTime.now().millisecondsSinceEpoch}.$fileExt";
        
        // Menggunakan uploadBinary agar universal
        await c.supabase.storage.from('daftar_alat').uploadBinary(path, _imageBytes!);
        imageUrl = c.supabase.storage.from('daftar_alat').getPublicUrl(path);
      }

      // 2. OTOMATIS SIMPAN KE TABEL DATABASE
      await c.supabase.from('alat').insert({
        'nama_alat': nameController.text.trim(),
        'id_kategori': int.parse(selectedKategori!),
        'stok_total': int.parse(stokController.text.trim()),
        'gambar_url': imageUrl, 
      });

      Get.back(result: true);

      // 3. BERHASIL - LANGSUNG KEMBALI
      Get.back(); 
      Get.snackbar(
        "Berhasil", 
        "Data alat telah disimpan",
        backgroundColor: const Color(0xFF1F3C58),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Gagal", 
        "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F3C58);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tambah Alat", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- AREA FOTO ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withOpacity(0.1)),
                          image: _imageBytes != null 
                            ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                            : null,
                        ),
                        child: _imageBytes == null 
                          ? const Center(child: Icon(Icons.add_a_photo_outlined, size: 40, color: primaryColor))
                          : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- INPUT NAMA ALAT ---
                  const Text(" Nama Alat", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "Masukkan nama alat",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                    validator: (value) => value == null || value.isEmpty ? "Nama alat tidak boleh kosong" : null,
                  ),
                  
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- DROPDOWN KATEGORI ---
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(" Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                            const SizedBox(height: 8),
                            FutureBuilder(
                              future: c.supabase.from('kategori').select().order('nama_kategori'),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const LinearProgressIndicator();
                                List data = snapshot.data as List;
                                return DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  value: selectedKategori,
                                  hint: const Text("Pilih"),
                                  items: data.map((kat) {
                                    return DropdownMenuItem<String>(
                                      value: kat['id_kategori'].toString(),
                                      child: Text(kat['nama_kategori']),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() => selectedKategori = val),
                                  validator: (value) => value == null ? "Wajib pilih" : null,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      // --- INPUT STOK ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(" Stok", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: stokController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Kosong";
                                if (int.tryParse(value) == null) return "Angka!";
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // --- TOMBOL SIMPAN ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveAlat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 5,
                      ),
                      child: const Text("Simpan", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}