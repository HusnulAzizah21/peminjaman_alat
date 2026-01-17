import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  var isLoading = false.obs;

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      
      // Melakukan login ke Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Ambil data role dari tabel public.users menggunakan UUID
        final userData = await _supabase
            .from('users')
            .select('role')
            .eq('id', response.user!.id)
            .single();

        String role = userData['role'];
        Get.offAllNamed('/dashboard', arguments: role);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}