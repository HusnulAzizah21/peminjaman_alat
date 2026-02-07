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
  
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  String? selectedRole;
  bool isLoading = false;
  bool obscurePass = true;

  final Color primaryColor = const Color(0xFF1F3C58);

  void _simpanData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        // 1. Daftar ke Auth agar bisa login
        final authRes = await c.supabase.auth.signUp(
          email: emailC.text.trim(),
          password: passC.text.trim(),
        );

        if (authRes.user != null) {
          // 2. Simpan ke tabel public agar password bisa DITAMPILKAN
          await c.supabase.from('users').insert({
            'id_user': authRes.user!.id,
            'nama': nameC.text.trim(),
            'email': emailC.text.trim(),
            'password': passC.text.trim(), // Teks asli disimpan di sini
            'role': selectedRole,
          });

          Get.back();
          Get.snackbar("Sukses", "User berhasil ditambahkan", backgroundColor: Colors.white);
        }
      } catch (e) {
        Get.snackbar("Error", e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Tambah Pengguna"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Nama"),
              TextFormField(controller: nameC, decoration: _buildInputDecoration("Nama"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
              const SizedBox(height: 15),
              _buildLabel("Email"),
              TextFormField(controller: emailC, decoration: _buildInputDecoration("Email"), validator: (v) => v!.isEmpty ? "Wajib diisi" : null),
              const SizedBox(height: 15),
              _buildLabel("Kata Sandi"),
              TextFormField(
                controller: passC,
                obscureText: obscurePass,
                decoration: _buildInputDecoration("Kata Sandi").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscurePass = !obscurePass),
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              _buildLabel("Sebagai"),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: _buildInputDecoration(""),
                items: ["Admin", "Petugas", "Peminjam"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => selectedRole = v),
                validator: (v) => v == null ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _simpanData,
                  child: isLoading ? const CircularProgressIndicator() : const Text("Simpan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Gunakan helper decoration Anda yang sebelumnya di sini
  InputDecoration _buildInputDecoration(String hint) => InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)));
  Widget _buildLabel(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold));
}