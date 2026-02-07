import 'package:flutter/material.dart';
import 'drawer.dart'; // Import file drawer yang dibuat tadi

class PetugasBerandaPage extends StatelessWidget {
  const PetugasBerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beranda Petugas"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F3C58),
        elevation: 0,
      ),
      // PANGGIL DRAWER DI SINI
      drawer: const PetugasDrawer(currentPage: '',), 
      body: const Center(
        child: Text("Konten Dashboard Petugas"),
      ),
    );
  }
}