import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';

class TambahPenggunaPage extends StatefulWidget {
  const TambahPenggunaPage({super.key});

  @override
  State<TambahPenggunaPage> createState() => _TambahPenggunaPageState();
}

class _TambahPenggunaPageState extends State<TambahPenggunaPage> {
  final c = Get.find<AppController>();
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk inputan
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  String? selectedRole;
  
  bool isLoading = false;
  bool obscurePass = true;

  final Color primaryColor = const Color(0xFF1F3C58);

  // FUNGSI SIMPAN: Menyimpan ke users dan mencatat ke log_aktivitas
  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        // 1. Simpan ke tabel users
        await c.supabase.from('users').insert({
          'nama': nameC.text.trim(),
          'email': emailC.text.trim(),
          'password': passC.text.trim(), 
          'role': selectedRole,
          'created_at': DateTime.now().toIso8601String(),
        });

        // 2. Catat aktivitas ke tabel log_aktivitas
        // Sesuai struktur tabelmu: id_user, aksi, keterangan, created_at
        await c.supabase.from('log_aktivitas').insert({
          'id_user': c.userProfile['id_user'], // ID Admin yang sedang login
          'aksi': 'Tambah User',
          'keterangan': 'Berhasil menambahkan user baru: ${nameC.text.trim()}',
          'created_at': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          // Tutup halaman dan beri sinyal 'true' agar halaman list di-refresh
          Get.back(result: true); 
          Get.snackbar(
            "Sukses", 
            "Pengguna berhasil ditambahkan",
            backgroundColor: Colors.green, 
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        Get.snackbar(
          "Gagal", 
          "Terjadi kesalahan: ${e.toString()}",
          backgroundColor: Colors.red, 
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Tambah Pengguna", 
          style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Nama Lengkap"),
              TextFormField(
                controller: nameC,
                decoration: _buildInputDecoration("Masukkan nama lengkap"),
                validator: (v) => v!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),

              _buildLabel("Email"),
              TextFormField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration("contoh@gmail.com"),
                validator: (v) => v!.isEmpty ? "Email tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),

              _buildLabel("Kata Sandi"),
              TextFormField(
                controller: passC,
                obscureText: obscurePass,
                decoration: _buildInputDecoration("Minimal 6 karakter").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: primaryColor),
                    onPressed: () => setState(() => obscurePass = !obscurePass),
                  ),
                ),
                validator: (v) => v!.length < 6 ? "Sandi minimal 6 karakter" : null,
              ),
              const SizedBox(height: 15),

              _buildLabel("Role / Jabatan"),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: _buildInputDecoration("Pilih Jabatan"),
                items: ["Admin", "Petugas", "Peminjam"]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRole = v),
                validator: (v) => v == null ? "Pilih salah satu role" : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: isLoading ? null : _simpanData,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text(
                        "Simpan Pengguna", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}