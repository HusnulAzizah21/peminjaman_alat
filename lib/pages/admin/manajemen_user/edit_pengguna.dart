import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';

class EditPenggunaPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditPenggunaPage({super.key, required this.userData});

  @override
  State<EditPenggunaPage> createState() => _EditPenggunaPageState();
}

class _EditPenggunaPageState extends State<EditPenggunaPage> {
  final c = Get.find<AppController>();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController nameC, emailC, passC;
  String? selectedRole;
  bool isLoading = false;
  bool obscurePass = true;

  final Color primaryColor = const Color(0xFF1F3C58);

  @override
  void initState() {
    super.initState();
    // Inisialisasi data dari widget.userData
    nameC = TextEditingController(text: (widget.userData['nama'] ?? "").toString());
    emailC = TextEditingController(text: (widget.userData['email'] ?? "").toString());
    passC = TextEditingController(text: (widget.userData['password'] ?? "").toString()); 
    selectedRole = widget.userData['role'];
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

Future<void> _updateData() async {
  if (_formKey.currentState!.validate()) {
    setState(() => isLoading = true);

    try {
      final userId = widget.userData['id_user']; 

      // Perintah untuk kirim data ke Supabase
      await c.supabase.from('users').update({
        'nama': nameC.text.trim(),
        'email': emailC.text.trim(),
        'password': passC.text.trim(),
        'role': selectedRole,
      }).eq('id_user', userId); // Pastikan id_user cocok

      if (mounted) {
        // result: true digunakan agar halaman manajemen_pengguna tahu dia harus refresh data
        Get.back(result: true); 
        Get.snackbar(
          "Sukses",
          "Data pengguna berhasil diperbarui",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal memperbarui: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    String initial = nameC.text.isNotEmpty ? nameC.text[0].toUpperCase() : "?";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Get.back(),
        ),
        title: const Text("Edit Pengguna", style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 35),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(initial, style: TextStyle(fontSize: 40, color: primaryColor)),
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("Nama"),
              TextFormField(
                controller: nameC,
                decoration: _buildInputDecoration("Masukkan nama"),
                validator: (v) => v!.isEmpty ? "Kolom nama wajib diisi!" : null,
              ),

              const SizedBox(height: 15),

              _buildLabel("Email"),
              TextFormField(
                controller: emailC,
                decoration: _buildInputDecoration("Masukkan email"),
                validator: (v) => v!.isEmpty ? "Kolom email wajib diisi!" : null,
              ),

              const SizedBox(height: 15),

              _buildLabel("Kata Sandi"),
              TextFormField(
                controller: passC,
                obscureText: obscurePass,
                decoration: _buildInputDecoration("Masukkan password").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: primaryColor),
                    onPressed: () => setState(() => obscurePass = !obscurePass),
                  ),
                ),
                validator: (v) => v!.length < 6 ? "Minimal 6 karakter" : null,
              ),

              const SizedBox(height: 15),

              _buildLabel("Sebagai"),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: _buildInputDecoration("Pilih Role"),
                items: ["Admin", "Petugas", "Peminjam"]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRole = v),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: isLoading ? null : _updateData,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }
}