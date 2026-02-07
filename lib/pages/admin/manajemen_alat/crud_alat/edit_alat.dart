import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../controllers/app_controller.dart';

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
  
  // Perubahan: selectedCategory sekarang menampung ID atau Nama kategori
  String? selectedCategory;
  List<String> _categories = []; // List untuk menyimpan kategori dari DB
  
  Uint8List? _imageBytes;
  String? _fileName;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.alat['nama_alat']);
    stockController = TextEditingController(text: widget.alat['stok_total'].toString());
    selectedCategory = widget.alat['nama_kategori']; // Default value dari data alat
    _fetchCategories();
  }

  // Ambil daftar kategori dari Supabase
  Future<void> _fetchCategories() async {
    try {
      final response = await c.supabase.from('kategori').select('nama_kategori');
      if (response != null) {
        setState(() {
          _categories = (response as List)
              .map((item) => item['nama_kategori'].toString())
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil kategori: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, 
    );

    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = pickedFile.name;
      });
    }
  }

  Future<void> _updateAlat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.alat['gambar_url'];

      if (_imageBytes != null && _fileName != null) {
        final fileExt = _fileName!.split('.').last;
        final path = 'alat/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        await c.supabase.storage.from('daftar_alat').uploadBinary(path, _imageBytes!);
        imageUrl = c.supabase.storage.from('daftar_alat').getPublicUrl(path);
      }

      // Cari id_kategori berdasarkan nama yang dipilih di dropdown
      final katRes = await c.supabase
          .from('kategori')
          .select('id_kategori')
          .eq('nama_kategori', selectedCategory!)
          .single();
      
      final int idKategori = katRes['id_kategori'];

      await c.supabase.from('alat').update({
        'nama_alat': nameController.text.trim(),
        'stok_total': int.parse(stockController.text.trim()),
        'id_kategori': idKategori, // Gunakan ID kategori hasil pencarian
        'gambar_url': imageUrl,
      }).eq('id_alat', widget.alat['id_alat']);

      Get.back(result: true); 
      
      Get.snackbar(
        "Sukses", 
        "Data berhasil diubah", 
        backgroundColor: const Color(0xFF1F3C58),
        colorText: Colors.white
      );
    } catch (e) {
      Get.snackbar("Error", "Gagal update: $e", backgroundColor: Colors.red.shade100);
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
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _imageBytes != null
                              ? Image.memory(_imageBytes!, fit: BoxFit.contain) 
                              : (widget.alat['gambar_url'] != null
                                  ? Image.network(widget.alat['gambar_url'], fit: BoxFit.contain) 
                                  : const Icon(Icons.monitor, size: 80)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F3C58),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                _buildLabel("Nama Alat"),
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration("Monitor"),
                  validator: (val) => val == null || val.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // DROPDOWN KATEGORI
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Kategori"),
                          DropdownButtonFormField<String>(
                            value: _categories.contains(selectedCategory) ? selectedCategory : null,
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedCategory = val;
                              });
                            },
                            decoration: _inputDecoration("Pilih Kategori"),
                            validator: (val) => val == null ? "Wajib pilih" : null,
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1F3C58)),
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
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("0"),
                            validator: (val) => val == null || val.isEmpty ? "Error" : null,
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
                    ),
                    child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(left: 5, bottom: 5),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFF1F3C58)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Color(0xFF1F3C58), width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
    );
  }
}