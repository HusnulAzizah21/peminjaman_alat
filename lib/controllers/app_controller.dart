import 'package:aplikasi_peminjamanbarang/login_page.dart';
import 'package:aplikasi_peminjamanbarang/pages/admin/manajemen_user/halaman_utama.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AppController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var userProfile = {}.obs;

  var emailError = "".obs;
  var passwordError = "".obs;

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Peringatan", "Email dan Password tidak boleh kosong");
      return;
    }

    try {
      isLoading.value = true;
      
      // Gunakan debugPrint untuk cek di konsol VS Code
      debugPrint("Mencoba Login: Email: '$email', Password: '$password'");

      final data = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      debugPrint("Respon Database: $data");

      if (data != null) {
        userProfile.value = data;
        String role = (data['role'] ?? 'Peminjam').toString();
        
        // PASTIIN NAMA ROUTE INI SUDAH ADA DI main.dart atau ganti ke Page-nya langsung
        if (role == 'Admin') {
          // Jika belum pakai GetPage routes, gunakan Get.offAll(() => NamaHalaman())
          Get.offAll(() => const ManajemenPenggunaPage()); 
        } else {
          Get.snackbar("Info", "Login berhasil sebagai $role");
        }

        Get.snackbar("Sukses", "Selamat datang, ${data['nama']}", 
          backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        // Jika data null, berarti kombinasi email & password tidak ada di tabel
        Get.snackbar("Gagal", "Email atau Password salah di database!", 
          backgroundColor: Colors.orange, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("Error Login: $e");
      Get.snackbar("Error", "Koneksi bermasalah: $e", 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    userProfile.value = {};
    Get.offAll(() => LoginPage());
  }
}