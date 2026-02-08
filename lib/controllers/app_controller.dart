import 'package:aplikasi_peminjamanbarang/login_page.dart';
import 'package:aplikasi_peminjamanbarang/pages/admin/beranda/beranda_admin.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/beranda/beranda.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/beranda/beranda_petugas.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AppController extends GetxController {
  final SupabaseClient supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var userProfile = {}.obs;
  var emailError = RxnString();
  var passwordError = RxnString();
  var isPasswordVisible = false.obs; // Logika visibility

  Future<void> login(String email, String password) async {
    // Reset error setiap kali tombol ditekan
    emailError.value = null;
    passwordError.value = null;

    // Validasi Kosong
    if (email.isEmpty) emailError.value = "Email tidak boleh kosong";
    if (password.isEmpty) passwordError.value = "Kata sandi tidak boleh kosong";
    if (email.isEmpty || password.isEmpty) return;

    try {
      isLoading.value = true;
      
      // Step 1: Cari user berdasarkan email
      final data = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (data == null) {
        emailError.value = "Email tidak terdaftar";
      } else {
        // Step 2: Cek password
        if (data['password'] != password) {
          passwordError.value = "Kata sandi salah";
        } else {
          // LOGIN BERHASIL
          userProfile.value = data;
          String role = data['role']?.toString() ?? 'Peminjam';
          
          Get.snackbar("Sukses", "Selamat datang, ${data['nama']}", 
              backgroundColor: Colors.green, colorText: Colors.white);

          // NAVIGASI BERDASARKAN ROLE
          if (role == 'Admin') {
            Get.offAll(() => const AdminBerandaPage()); 
          } else if (role == 'Petugas') {
            Get.offAll(() => const PetugasBerandaPage()); 
          } else {
            Get.offAll(() => const PeminjamPage());
          }
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Koneksi bermasalah: $e", 
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    userProfile.value = {};
    Get.offAll(() => const LoginPage());
  }
}