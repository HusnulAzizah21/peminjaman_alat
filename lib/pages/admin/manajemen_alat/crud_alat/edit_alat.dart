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
  
  String? selectedCategory;
  List<String> _categories = []; 
  
  Uint8List? _imageBytes;
  String? _fileName;
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
      String imageUrl = widget.alat['gambar_url'] ?? "";

      // 1. Upload Gambar jika ada perubahan
      if (_imageBytes != null && _fileName != null) {
        final path = 'alat/${DateTime.now().millisecondsSinceEpoch}_$_fileName';
        await c.supabase.storage.from('daftar_alat').uploadBinary(path, _imageBytes!);
        imageUrl = c.supabase.storage.from('daftar_alat').getPublicUrl(path);
      }

      // 2. Ambil ID Kategori berdasarkan nama yang dipilih di dropdown
      final katRes = await c.supabase
          .from('kategori')
          .select('id_kategori')
          .eq('nama_kategori', selectedCategory!)
          .single();

      // 3. Eksekusi Update ke Database
      // CATATAN: 'updated_at' dihapus agar tidak error PGRST204
      await c.supabase.from('alat').update({
        'nama_alat': nameController.text.trim(),
        'stok_total': int.parse(stockController.text.trim()),
        'id_kategori': katRes['id_kategori'],
        'gambar_url': imageUrl,
      }).eq('id_alat', widget.alat['id_alat']);

      // 4. KUNCI AUTO-REFRESH: Kirim result 'true' saat kembali
      if (mounted) {
        Get.back(result: true); 
        Get.snackbar("Sukses", "Data alat berhasil diperbarui",
            backgroundColor: Colors.white, colorText: const Color(0xFF1F3C58));
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      Get.snackbar("Error", "Gagal memperbarui data: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              crossAxisAlignment: CrossAxisAlignment.start, // Memastikan semua Column internal mulai dari kiri
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

                Center( // Tetap di tengah untuk bagian gambar
                  child: GestureDetector(
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
                ),

                const SizedBox(height: 40),
                _buildLabel("Nama Alat"),
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration("Monitor"),
                  validator: (val) => val == null || val.isEmpty ? "Kolom wajib diisi!" : null,
                ),
                const SizedBox(height: 20),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            validator: (val) => val == null ? "Kolom wajib diisi!" : null,
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1F3C58)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    // KOLOM STOK
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Stok"),
                          TextFormField(
                            controller: stockController,
                            textAlign: TextAlign.start, // Rata kiri untuk teks input
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("0"),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return "Kolom wajib diisi!";
                              }
                              // Regex untuk memastikan hanya angka yang dimasukkan
                              if (!RegExp(r'^[0-9]+$').hasMatch(val)) {
                                return "Masukkan angka!";
                              }
                              return null;
                            },
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
                const SizedBox(height: 20),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
    );
  }
}