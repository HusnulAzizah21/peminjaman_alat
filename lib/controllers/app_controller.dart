import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/admin/admin_page.dart';
import '../pages/petugas/petugas_page.dart';
import '../pages/peminjam/beranda.dart';
import '../pages/login_page.dart';

class AppController extends GetxController {
  final supabase = Supabase.instance.client;

  var isLoading = false.obs;
  var emailError = ''.obs;
  var passwordError = ''.obs;

  Future<void> login(String email, String password) async {
    emailError.value = '';
    passwordError.value = '';

    if (email.isEmpty) {
      emailError.value = 'Email tidak boleh kosong';
      return;
    }
    if (password.isEmpty) {
      passwordError.value = 'Password tidak boleh kosong';
      return;
    }

    try {
      isLoading.value = true;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        isLoading.value = false;
        return;
      }

      // Pastikan nama tabel sama dengan yang ada di SplashPage (Gunakan 'profiles')
      final profile = await supabase
          .from('users') 
          .select()
          .eq('id_user', user.id)
          .maybeSingle();

      if (profile == null) {
        Get.snackbar("Error", "Data profil tidak ditemukan.");
        isLoading.value = false;
        return;
      }

      final role = profile['role'];

      if (role == 'Admin') {
        Get.offAll(() => const AdminPage());
      } else if (role == 'Petugas') {
        Get.offAll(() => const PetugasPage());
      } else {
        Get.offAll(() => const PeminjamPage());
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        emailError.value = 'Email atau kata sandi salah';
      } else {
        Get.snackbar("Login Gagal", e.message);
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    Get.offAll(() => LoginPage());
  }
}