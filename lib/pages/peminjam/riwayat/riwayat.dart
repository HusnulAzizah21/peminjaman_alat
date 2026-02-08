import 'package:flutter/material.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Peminjaman"),
        backgroundColor: const Color(0xFF1F3C58),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Halaman Daftar Riwayat", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}