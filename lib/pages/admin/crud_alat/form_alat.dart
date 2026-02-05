import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';

class FormAlatPage extends StatefulWidget {
  final Map<String, dynamic>? alat; 
  const FormAlatPage({super.key, this.alat});

  @override
  State<FormAlatPage> createState() => _FormAlatPageState();
}

class _FormAlatPageState extends State<FormAlatPage> {
  final c = Get.find<AppController>();
  final nameController = TextEditingController();
  final stockController = TextEditingController();
  final imgController = TextEditingController();
  
  String? selectedKategoriId;
  List<Map<String, dynamic>> kategoriList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadKategori();
    if (widget.alat != null) {
      nameController.text = widget.alat!['nama_alat'] ?? "";
      stockController.text = (widget.alat!['stok_total'] ?? 0).toString();
      imgController.text = widget.alat!['gambar_url'] ?? "";
      selectedKategoriId = widget.alat!['kategori_id']?.toString();
    }
  }

  Future<void> _loadKategori() async {
    try {
      final data = await c.supabase.from('kategori').select();
      setState(() {
        kategoriList = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Error kategori: $e");
    }
  }

  Future<void> _saveAlat() async {
    if (nameController.text.isEmpty || stockController.text.isEmpty || selectedKategoriId == null) {
      Get.snackbar("Peringatan", "Data tidak lengkap");
      return;
    }

    setState(() => isLoading = true);
    final data = {
      'nama_alat': nameController.text,
      'stok_total': int.parse(stockController.text),
      'gambar_url': imgController.text,
      'kategori_id': int.parse(selectedKategoriId!),
    };

    try {
      if (widget.alat == null) {
        await c.supabase.from('alat').insert(data);
      } else {
        await c.supabase.from('alat').update(data).eq('id', widget.alat!['id']);
      }
      Get.back();
      Get.snackbar("Sukses", "Data berhasil diperbarui");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.alat == null ? "Tambah Alat" : "Edit Alat"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F3C58),
        elevation: 0,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildField(nameController, "Nama Alat", Icons.inventory),
                const SizedBox(height: 15),
                _buildField(stockController, "Jumlah Stok", Icons.numbers, isNumber: true),
                const SizedBox(height: 15),
                _buildField(imgController, "URL Gambar", Icons.image),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedKategoriId,
                  decoration: InputDecoration(
                    labelText: "Pilih Kategori",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: kategoriList.map((k) => DropdownMenuItem(
                    value: k['id'].toString(),
                    child: Text(k['nama_kategori']),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedKategoriId = v),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveAlat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3C58),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}