import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_page.dart';
import 'controllers/app_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'https://jzlbnuarsuoyffzbcter.supabase.co',
    anonKey: 'sb_publishable_kbx50_AKpUfDD2UEjd1M1g_GrUN15Ui',
  );
  
  // Cukup satu kali di sini
  Get.put(AppController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // HAPUS Get.put di sini, sudah ada di main()
    return GetMaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}