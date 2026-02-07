import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';

class EditPenggunaPage extends StatefulWidget {
  final Map userData;
  const EditPenggunaPage({super.key, required this.userData});

  @override
  State<EditPenggunaPage> createState() => _EditPenggunaPageState();
}

class _EditPenggunaPageState extends State<EditPenggunaPage> {
  final c = Get.find<AppController>();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameC;
  late TextEditingController emailC;
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    nameC = TextEditingController(text: widget.userData['nama']);
    emailC = TextEditingController(text: widget.userData['email']);
    selectedRole = widget.userData['role'];
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F3C58);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Edit Pengguna"), centerTitle: true, foregroundColor: primaryColor, backgroundColor: Colors.white, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameC,
                decoration: InputDecoration(labelText: "Nama", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                validator: (v) => v!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: emailC,
                decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                validator: (v) => v!.isEmpty ? "Email tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(labelText: "Role", border: OutlineInputBorder(borderRadius: BorderRadius.circular(30))),
                items: ["Admin", "Petugas", "Peminjam"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => selectedRole = v,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await c.supabase.from('users').update({'nama': nameC.text, 'email': emailC.text, 'role': selectedRole}).eq('id_user', widget.userData['id_user']);
                      Get.back();
                      Get.snackbar("Berhasil", "Data diperbarui", backgroundColor: primaryColor, colorText: Colors.white);
                    }
                  },
                  child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}