import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI SUPABASE ---
  await Supabase.initialize(
    url: 'https://jzlbnuarsuoyffzbcter.supabase.co',
    anonKey: 'sb_publishable_kbx50_AKpUfDD2UEjd1M1g_GrUN15Ui',
  );

  runApp(const MyApp());
}

// ==========================================================
// 1. DATA MODEL
// ==========================================================
class AlatModel {
  final int id;
  final String namaAlat;
  final int stokTotal;
  final String? namaKategori;

  AlatModel({required this.id, required this.namaAlat, required this.stokTotal, this.namaKategori});

  factory AlatModel.fromJson(Map<String, dynamic> json) {
    return AlatModel(
      id: json['id'],
      namaAlat: json['nama_alat'],
      stokTotal: json['stok_total'],
      namaKategori: json['kategori'] != null ? json['kategori']['nama_kategori'] : '-',
    );
  }
}

// ==========================================================
// 2. CONTROLLER (LOGIKA BISNIS)
// ==========================================================
class AppController extends GetxController {
  final _supabase = Supabase.instance.client;
  var isLoading = false.obs;
  var listAlat = <AlatModel>[].obs;

  // Logika Login
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      
      if (response.user != null) {
        Get.offAll(() => const AlatPage());
      }
    } catch (e) {
      Get.snackbar("Login Gagal", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Logika Ambil Data Alat & Kategori (Join Table)
  Future<void> fetchAlat() async {
    try {
      isLoading.value = true;
      final data = await _supabase.from('alat').select('*, kategori(nama_kategori)');
      listAlat.value = (data as List).map((e) => AlatModel.fromJson(e)).toList();
    } catch (e) {
      Get.snackbar("Error Data", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    Get.offAll(() => LoginPage());
  }
}

// ==========================================================
// 3. UI - LOGIN PAGE
// ==========================================================
class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final c = Get.put(AppController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Sistem Alat")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            Obx(() => c.isLoading.value 
              ? const CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: () => c.login(emailController.text, passController.text),
                  child: const Text("Masuk"),
                )),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 4. UI - ALAT & KATEGORI PAGE
// ==========================================================
class AlatPage extends StatefulWidget {
  const AlatPage({super.key});
  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  final c = Get.find<AppController>();

  @override
  void initState() {
    super.initState();
    c.fetchAlat(); // Ambil data saat halaman dibuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Alat"),
        actions: [IconButton(onPressed: () => c.logout(), icon: const Icon(Icons.logout))],
      ),
      body: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.listAlat.isEmpty) return const Center(child: Text("Tidak ada alat tersedia"));
        
        return RefreshIndicator(
          onRefresh: () => c.fetchAlat(),
          child: ListView.builder(
            itemCount: c.listAlat.length,
            itemBuilder: (context, index) {
              final alat = c.listAlat[index];
              return ListTile(
                leading: const Icon(Icons.build),
                title: Text(alat.namaAlat),
                subtitle: Text("Kategori: ${alat.namaKategori}"),
                trailing: Text("Stok: ${alat.stokTotal}", style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        );
      }),
    );
  }
}

// ==========================================================
// 5. MAIN APP WRAPPER
// ==========================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // Cek apakah ada session aktif
      home: Supabase.instance.client.auth.currentSession == null 
          ? LoginPage() 
          : const AlatPage(),
    );
  }
}