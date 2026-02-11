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
  final SupabaseClient supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var userProfile = {}.obs;
  var emailError = RxnString();
  var passwordError = RxnString();
  var isPasswordVisible = false.obs;

  // --- 1. GOOGLE SIGN IN ---
  Future<void> signInWithGoogle() async {
  try {
    isLoading.value = true;

    // 1. Inisialisasi yang BENAR untuk Web vs Mobile
    final GoogleSignIn googleSignIn = GoogleSignIn(
      // Web HANYA butuh clientId. Android butuh keduanya.
      clientId: '351912784268-v54gl2eb6t8vricnrbveoo4ciaffhgm9.apps.googleusercontent.com',
      serverClientId: kIsWeb ? null : '351912784268-v54gl2eb6t8vricnrbveoo4ciaffhgm9.apps.googleusercontent.com',
    );

    // 2. Bersihkan session agar tidak langsung login otomatis
    await googleSignIn.signOut();
    await supabase.auth.signOut();

    // 3. Mulai Sign In
    final googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      isLoading.value = false;
      return; 
    }

    final googleAuth = await googleUser.authentication;
    
    // LOGIKA KRUSIAL: Web terkadang hanya mengirim accessToken atau idToken
    // Supabase signInWithIdToken butuh idToken yang valid.
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw 'No ID Token found. Pastikan OAuth Client ID di Google Console bertipe "Web Application".';
    }

    // 4. Kirim ke Supabase
    final AuthResponse res = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (res.user != null) {
      userProfile.value = {
        'id_user': res.user!.id,
        'nama': res.user!.userMetadata?['full_name'] ?? googleUser.displayName,
        'email': res.user!.email,
        'role': 'Peminjam',
      };
      Get.offAll(() => const PeminjamPage());
    }
  } catch (error) {
    print('Error Google Sign In: $error');
    Get.snackbar("Login Gagal", "Terjadi kesalahan: $error", backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    isLoading.value = false;
  }
} // <-- Tadi kelebihan kurung kurawal di sini

  // --- 2. LOGIN MANUAL ---
  Future<void> login(String email, String password) async {
    emailError.value = null;
    passwordError.value = null;

    if (email.isEmpty) emailError.value = "Email tidak boleh kosong";
    if (password.isEmpty) passwordError.value = "Kata sandi tidak boleh kosong";
    if (email.isEmpty || password.isEmpty) return;

    try {
      isLoading.value = true;
      
      final data = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (data == null) {
        emailError.value = "Email tidak terdaftar";
      } else {
        if (data['password'] != password) {
          passwordError.value = "Kata sandi salah";
        } else {
          userProfile.value = data;
          String role = data['role']?.toString() ?? 'Peminjam';
          
          Get.snackbar("Sukses", "Selamat datang, ${data['nama']}", 
              backgroundColor: Colors.green, colorText: Colors.white);

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

  // --- 3. LOGOUT ---
  void logout() async {
  await supabase.auth.signOut(); // Menghapus sesi di Supabase
  await GoogleSignIn().signOut(); // Menghapus sesi di Google
  userProfile.value = {}; // Mengosongkan data user di GetX
  Get.offAll(() => const LoginPage()); // Tendang balik ke Login
}
}
