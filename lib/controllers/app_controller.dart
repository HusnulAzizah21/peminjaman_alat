import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/admin/manajemen_alat/admin_page.dart';
import '../pages/petugas/petugas_page.dart';
import '../pages/peminjam/beranda.dart';
import '../login_page.dart';

class AppController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var emailError = ''.obs;
  var passwordError = ''.obs;

  Future<void> login(String email, String password) async {
    // 1. Reset error setiap kali tombol ditekan
    emailError.value = '';
    passwordError.value = '';

    // 2. Cek validasi input kosong (Lokal)
    if (email.isEmpty) emailError.value = 'Email tidak boleh kosong';
    if (password.isEmpty) passwordError.value = 'Password tidak boleh kosong';
    if (email.isEmpty || password.isEmpty) return;

    try {
      isLoading.value = true;

      // 3. Proses Login ke Supabase Auth
      try {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = supabase.auth.currentUser;
        if (user != null) {
          final profile = await supabase
              .from('users')
              .select()
              .eq('id_user', user.id)
              .maybeSingle();

          if (profile != null) {
            final role = profile['role'];
            if (role == 'Admin') {
              Get.offAll(() => const AdminPage());
            } else if (role == 'Petugas') {
              Get.offAll(() => const PetugasBerandaPage());
            } else {
              Get.offAll(() => const PeminjamPage());
            }
          }
        }
      } on AuthException catch (e) {
        // --- LOGIKA PESAN DI BAWAH KOLOM ---
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          // Set pesan yang sama ke kedua field
          emailError.value = 'Email atau kata sandi salah';
          passwordError.value = 'Email atau kata sandi salah';
        } else {
          Get.snackbar("Login Gagal", e.message);
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan sistem: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      Get.offAll(() => LoginPage());
    } catch (e) {
      Get.snackbar("Error", "Gagal Logout: $e");
    }
  }
}