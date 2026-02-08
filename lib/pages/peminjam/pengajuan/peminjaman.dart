import 'package:flutter/material.dart';

class PeminjamanPage extends StatelessWidget {
  const PeminjamanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Peminjaman Barang"),
        backgroundColor: const Color(0xFF1F3C58),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Halaman Form Peminjaman", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}