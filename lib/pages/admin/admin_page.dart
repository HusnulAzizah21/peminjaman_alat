import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AppController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => c.logout(),
          )
        ],
      ),
      body: const Center(
        child: Text("Halaman Admin", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
