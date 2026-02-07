import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/splash_page.dart';
import 'controllers/app_controller.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jzlbnuarsuoyffzbcter.supabase.co',
    anonKey: 'sb_publishable_kbx50_AKpUfDD2UEjd1M1g_GrUN15Ui',
  );
  Get.put(AppController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AppController());

    return GetMaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        // Mengatur font utama aplikasi
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(), // ✅ SPLASH SCREEN
    );
  }
}
