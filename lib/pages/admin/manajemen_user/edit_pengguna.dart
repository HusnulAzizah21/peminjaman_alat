import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool isProcessing = false; // Untuk mencegah multiple clicks

  final Color primaryColor = const Color(0xFF1F3C58);

  @override
  void initState() {
    super.initState();
    // Proteksi data NULL agar tidak layar merah
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

  Future<void> _updateAuthUser(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Cek apakah email atau password berubah
      final oldEmail = widget.userData['email']?.toString() ?? "";
      final oldPassword = widget.userData['password']?.toString() ?? "";
      final newEmail = emailC.text.trim();
      final newPassword = passC.text.trim();
      
      // Hanya update auth jika email berubah atau password tidak kosong
      bool shouldUpdateAuth = false;
      Map<String, dynamic> attributesToUpdate = {};
      
      if (oldEmail != newEmail) {
        attributesToUpdate['email'] = newEmail;
        shouldUpdateAuth = true;
      }
      
      // Hanya update password jika diisi (tidak kosong)
      if (newPassword.isNotEmpty && oldPassword != newPassword) {
        attributesToUpdate['password'] = newPassword;
        shouldUpdateAuth = true;
      }
      
      // Selalu update user metadata
      attributesToUpdate['user_metadata'] = {
        "role": selectedRole,
        "name": nameC.text.trim(),
      };
      
      if (shouldUpdateAuth) {
        print("Mengupdate auth user...");
        final attrs = AdminUserAttributes(
          email: attributesToUpdate['email'] as String?,
          password: attributesToUpdate['password'] as String?,
          userMetadata: attributesToUpdate['user_metadata'] as Map<String, dynamic>?,
        );
        
        final response = await supabase.auth.admin.updateUserById(
          userId,
          attributes: attrs,
        );
        
        print("Auth update success: ${response.user?.email}");
      } else {
        print("Tidak perlu update auth (email & password tidak berubah)");
      }
    } on AuthException catch (e) {
      // Tangkap error spesifik dari Supabase Auth
      if (e.message.contains('over_email_send_rate_limit')) {
        // Lempar error khusus untuk ditangani di _updateData
        throw Exception("RATE_LIMIT_ERROR");
      } else {
        print("AuthException: ${e.message}");
        // Lempar kembali untuk ditangani di _updateData
        throw e;
      }
    } catch (e) {
      print("Error updating auth: $e");
      // Jangan lempar error, biarkan proses database tetap berhasil
    }
  }

  void _updateData() async {
    if (_formKey.currentState!.validate()) {
      // Cegah multiple clicks
      if (isProcessing) {
        Get.snackbar(
          "Perhatian",
          "Sedang memproses...",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      
      setState(() {
        isLoading = true;
        isProcessing = true;
      });
      
      try {
        final userId = widget.userData['id_user'];

        // 1. UPDATE TABEL PUBLIC (Database) - PRIORITAS UTAMA
        await c.supabase.from('users').update({
          'nama': nameC.text.trim(),
          'email': emailC.text.trim(),
          'password': passC.text.trim(),
          'role': selectedRole,
          'updated_at': DateTime.now().toIso8601String(), // Tambah timestamp
        }).eq('id_user', userId);

        // 2. UPDATE AUTH (jika diperlukan) - OPTIONAL
        try {
          await _updateAuthUser(userId);
        } on Exception catch (e) {
          if (e.toString().contains('RATE_LIMIT_ERROR')) {
            // Kasus khusus: rate limit, tetap sukses karena database sudah diupdate
            Get.back();
            Get.snackbar(
              "Sukses dengan Catatan",
              "Data berhasil disimpan di database.\nPerubahan email/auth memerlukan waktu 1 menit sebelum dapat diubah lagi.",
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            return;
          }
        } catch (e) {
          // Error lain dari auth, abaikan karena database sudah sukses
          print("Auth update error (diabaikan): $e");
        }

        Get.back();
        Get.snackbar(
          "Sukses", 
          "Data pengguna berhasil diperbarui",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } on AuthException catch (e) {
        // Tangani error spesifik dari Supabase Auth
        if (e.message.contains('over_email_send_rate_limit')) {
          Get.snackbar(
            "Rate Limit", 
            "Terlalu banyak permintaan perubahan email. Tunggu 50 detik sebelum mencoba lagi.\nData sudah disimpan di database.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        } else {
          Get.snackbar(
            "Error Auth", 
            "Error: ${e.message}\nData sudah disimpan di database.",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      } catch (e) {
        print("Error utama: $e");
        Get.snackbar(
          "Error", 
          "Terjadi kesalahan: ${e.toString()}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } finally {
        setState(() => isLoading = false);
        
        // Reset processing flag setelah delay untuk mencegah rate limit
        Future.delayed(const Duration(seconds: 60), () {
          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }
        });
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
        title: const Text(
          "Edit Pengguna",
          style: TextStyle(color: Color(0xFF1F3C58), fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
                  child: Text(
                    initial,
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Info rate limit
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Perubahan email maksimal 1x per menit",
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildLabel("Nama"),
              TextFormField(
                controller: nameC,
                style: const TextStyle(fontSize: 13),
                decoration: _buildInputDecoration("Masukkan nama"),
                validator: (v) => v!.isEmpty ? "Nama wajib diisi" : null,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 15),

              _buildLabel("Email"),
              TextFormField(
                controller: emailC,
                style: const TextStyle(fontSize: 13),
                decoration: _buildInputDecoration("Email"),
                validator: (v) {
                  if (v!.isEmpty) return "Email wajib diisi";
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                    return "Format email tidak valid";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              _buildLabel("Kata Sandi"),
              TextFormField(
                controller: passC,
                obscureText: obscurePass,
                style: const TextStyle(fontSize: 13),
                decoration: _buildInputDecoration("Kosongkan jika tidak ingin mengubah").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: primaryColor, size: 20),
                    onPressed: () => setState(() => obscurePass = !obscurePass),
                  ),
                ),
                // Password tidak wajib (opsional untuk diubah)
                validator: null,
              ),
              
              Container(
                padding: const EdgeInsets.only(top: 5, left: 10),
                child: Text(
                  "Biarkan kosong jika tidak ingin mengubah password",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              _buildLabel("Sebagai"),
              DropdownButtonFormField<String>(
                value: selectedRole,
                style: const TextStyle(fontSize: 13, color: Colors.black),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1F3C58)),
                decoration: _buildInputDecoration("Pilih Role"),
                items: ["Admin", "Petugas", "Peminjam"]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => selectedRole = v),
                validator: (v) => v == null ? "Role wajib dipilih" : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    // Disable jika sedang processing
                    foregroundColor: isProcessing ? Colors.grey[300] : null,
                  ),
                  onPressed: (isLoading || isProcessing) ? null : _updateData,
                  child: isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(
                          color: Colors.white, 
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isProcessing) ...[
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            isProcessing ? "Memproses..." : "Simpan Perubahan",
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF1F3C58), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF1F3C58), width: 2),
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