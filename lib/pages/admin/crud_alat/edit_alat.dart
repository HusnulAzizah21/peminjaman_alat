import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../controllers/app_controller.dart';

class EditAlatPage extends StatefulWidget {
  final Map<String, dynamic> alat;

  const EditAlatPage({super.key, required this.alat});

  @override
  State<EditAlatPage> createState() => _EditAlatPageState();
}

class _EditAlatPageState extends State<EditAlatPage> {
  final AppController c = Get.find<AppController>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController stockController;
  String? selectedCategory;
  List<Map<String, dynamic>> categories = [];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.alat['nama_alat']);
    stockController = TextEditingController(text: widget.alat['stok_total'].toString());
    selectedCategory = widget.alat['nama_kategori'];
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final response = await c.supabase.from('kategori').select();
    setState(() {
      categories = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateAlat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.alat['gambar_url'];

      // 1. Upload Gambar jika ada file baru
      if (_imageFile != null) {
        final fileName = 'alat_${DateTime.now().millisecondsSinceEpoch}.png';
        final path = 'daftar_alat/$fileName';
        
        await c.supabase.storage.from('alat_images').upload(path, _imageFile!);
        imageUrl = c.supabase.storage.from('alat_images').getPublicUrl(path);
      }

      // 2. Update Database
      await c.supabase.from('alat').update({
        'nama_alat': nameController.text,
        'stok_total': int.parse(stockController.text),
        'gambar_url': imageUrl,
        // Jika tabel butuh id_kategori, cari ID-nya:
        'id_kategori': categories.firstWhere((cat) => cat['nama_kategori'] == selectedCategory)['id'],
      }).eq('id', widget.alat['id']);

      Get.back();
      Get.snackbar("Sukses", "Data alat berhasil diperbarui", 
          backgroundColor: Colors.white, colorText: const Color(0xFF1F3C58));
    } catch (e) {
      Get.snackbar("Error", e.toString(), backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F3C58)))
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F3C58)),
                          onPressed: () => Get.back(),
                        ),
                        const Expanded(
                          child: Text(
                            "Edit Alat",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F3C58)),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Upload/Preview Gambar
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 120,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.contain)
                                : (widget.alat['gambar_url'] != null
                                    ? Image.network(widget.alat['gambar_url'], fit: BoxFit.contain)
                                    : const Icon(Icons.monitor, size: 80, color: Colors.black87)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFF1F3C58), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildLabel("Nama Alat"),
                    TextFormField(
                      controller: nameController,
                      decoration: _inputDecoration("Nama Alat"),
                      validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Kategori"),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                items: categories.map((cat) => DropdownMenuItem(
                                  value: cat['nama_kategori'].toString(),
                                  child: Text(cat['nama_kategori'].toString()),
                                )).toList(),
                                onChanged: (val) => setState(() => selectedCategory = val),
                                decoration: _inputDecoration("Kategori"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Stok"),
                              TextFormField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: _inputDecoration("0"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _updateAlat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F3C58),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 4,
                        ),
                        child: const Text("Simpan", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Text(text, style: const TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFF1F3C58)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
    );
  }
}