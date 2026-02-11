import 'package:aplikasi_peminjamanbarang/login_page.dart';
import 'package:aplikasi_peminjamanbarang/pages/admin/beranda/beranda_admin.dart';
import 'package:aplikasi_peminjamanbarang/pages/peminjam/beranda/beranda.dart';
import 'package:aplikasi_peminjamanbarang/pages/petugas/beranda/beranda_petugas.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppController extends GetxController {
  var dataUser = {}.obs;
  final SupabaseClient supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var userProfile = {}.obs;
  var emailError = RxnString();
  var passwordError = RxnString();
  var isPasswordVisible = false.obs; // Logika visibility

  Future<void> signInWithGoogle() async {
  try {
    // 1. Inisialisasi Google Sign In
    // Untuk Android, masukkan serverClientId (diambil dari Web Client ID di Google Console)
    final googleSignIn = GoogleSignIn(
  clientId: '351912784268-v54gl2eb6t8vricnrbveoo4ciaffhgm9.apps.googleusercontent.com',
  // Kita beri syarat: kalau Web (kIsWeb), serverClientId-nya dikosongkan (null)
  serverClientId: kIsWeb ? null : '351912784268-v54gl2eb6t8vricnrbveoo4ciaffhgm9.apps.googleusercontent.com',
);
    
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw 'No Access Token or ID Token found.';
    }

    // 2. Kirim kredensial ke Supabase
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    
    // 3. Navigasi ke Beranda setelah berhasil
    Get.offAllNamed('/dashboard');

  } catch (error) {
    print('Error Google Sign In: $error');
  }
}

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
            Get.offAll(() => const BerandaPetugas()); 
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