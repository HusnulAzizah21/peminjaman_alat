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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F3C58);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Tambah Pengguna"), centerTitle: true, foregroundColor: primaryColor, backgroundColor: Colors.white, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameC,
                decoration: InputDecoration(labelText: "Nama", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: emailC,
                decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                validator: (v) => v!.isEmpty ? "Email wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: passC,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                validator: (v) => v!.isEmpty ? "Password wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Role", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                items: ["Admin", "Petugas", "Peminjam"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => selectedRole = v,
                validator: (v) => v == null ? "Role wajib dipilih" : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      await c.supabase.from('users').insert({'nama': nameC.text, 'email': emailC.text, 'password': passC.text, 'role': selectedRole});
                      Get.back();
                    }
                  },
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}