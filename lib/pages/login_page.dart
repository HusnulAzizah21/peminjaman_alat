import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final emailC = TextEditingController();
  final passC = TextEditingController();
  final c = Get.find<AppController>();
  final isPasswordHidden = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg_sekolah.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Putih-putih Container Login
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SiBrantas",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F3C58))),
                    const SizedBox(height: 8),
                    const Text("Silahkan masuk terlebih dahulu !",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F3C58))),
                    const SizedBox(height: 40),

                    // --- INPUT EMAIL ---
                    Obx(() => TextField(
                          controller: emailC,
                          decoration: InputDecoration(
                            hintText: "Masukkan email",
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Color(0xFF1F3C58)),
                            // Menampilkan error di bawah kolom
                            errorText: c.emailError.value.isEmpty
                                ? null
                                : c.emailError.value,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1F3C58))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1F3C58), width: 2)),
                          ),
                        )),

                    const SizedBox(height: 16),

                    // --- INPUT PASSWORD ---
                    Obx(() => TextField(
                          controller: passC,
                          obscureText: isPasswordHidden.value,
                          decoration: InputDecoration(
                            hintText: "Masukkan kata sandi",
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: Color(0xFF1F3C58)),
                            // Menampilkan error di bawah kolom
                            errorText: c.passwordError.value.isEmpty
                                ? null
                                : c.passwordError.value,
                            suffixIcon: IconButton(
                              icon: Icon(
                                  isPasswordHidden.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF1F3C58)),
                              onPressed: () => isPasswordHidden.toggle(),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1F3C58))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1F3C58), width: 2)),
                          ),
                        )),

                    const SizedBox(height: 30),

                    // --- TOMBOL MASUK ---
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F3C58),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: c.isLoading.value
                                ? null
                                : () => c.login(
                                    emailC.text.trim(), passC.text.trim()),
                            child: c.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Masuk",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}