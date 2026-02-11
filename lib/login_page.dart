import 'package:aplikasi_peminjamanbarang/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/app_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  
  // Inisialisasi AppController
  final AppController authC = Get.put(AppController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bg_sekolah.jpg'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SiBrantas", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F3C58))),
                  const Text("Silahkan masuk terlebih dahulu !"),
                  const SizedBox(height: 30),

                  // KOLOM EMAIL
                  Obx(() => TextField(
                    controller: emailC,
                    decoration: InputDecoration(
                      hintText: "Masukkan email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: authC.emailError.value,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  )),

                  const SizedBox(height: 20),

                  // KOLOM PASSWORD
                  Obx(() => TextField(
                    controller: passC,
                    obscureText: !authC.isPasswordVisible.value,
                    decoration: InputDecoration(
                      hintText: "Masukkan kata sandi",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          authC.isPasswordVisible.value 
                            ? Icons.visibility 
                            : Icons.visibility_off,
                        ),
                        onPressed: () => authC.isPasswordVisible.toggle(),
                      ),
                      errorText: authC.passwordError.value,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  )),

                  const SizedBox(height: 40),

                  // TOMBOL MASUK
                  Obx(() => ElevatedButton(
                    onPressed: authC.isLoading.value 
                        ? null 
                        : () => authC.login(emailC.text.trim(), passC.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F3C58),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: authC.isLoading.value 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Masuk", style: TextStyle(color: Colors.white, fontSize: 16)),
                  )),

                  ElevatedButton.icon(
                    onPressed: () => authC.signInWithGoogle(), // Panggil fungsi di controller
                    icon: const Icon(Icons.login, color: Colors.red),
                    label: const Text("Masuk dengan Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}