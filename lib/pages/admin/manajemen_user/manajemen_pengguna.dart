import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/app_controller.dart';
import '../drawer.dart';
import 'tambah_pengguna.dart';
import 'edit_pengguna.dart';

class ManajemenPenggunaPage extends StatefulWidget {
  const ManajemenPenggunaPage({super.key});

  @override
  State<ManajemenPenggunaPage> createState() => _ManajemenPenggunaPageState();
}

class _ManajemenPenggunaPageState extends State<ManajemenPenggunaPage> {
  final c = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);
  
  // State untuk filter
  String selectedRole = 'Semua';
  String searchQuery = '';

  // Fungsi Refresh Data
  void _refreshData() {
    setState(() {});
  }

  // Fungsi Hapus User
  void _deleteUser(Map user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Hapus"),
        content: Text("Hapus pengguna ${user['nama']}?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              await c.supabase.from('users').delete().eq('id_user', user['id_user']);
              Get.back();
              _refreshData();
              Get.snackbar("Sukses", "Data berhasil dihapus", backgroundColor: Colors.orange, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manajemen Pengguna", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
      ),
      drawer: const AdminDrawer(currentPage: 'Manajemen Pengguna'),
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari nama pengguna...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 2. TAB FILTER ROLE (Admin, Petugas, Peminjam)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: ["Admin", "Petugas", "Peminjam"].map((role) {
                bool isSelected = selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedRole = role),
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // 3. LIST DATA DARI SUPABASE
          Expanded(
            child: FutureBuilder(
              // Memanggil tabel 'users' difilter berdasarkan role
              future: c.supabase
                  .from('users')
                  .select()
                  .eq('role', selectedRole)
                  .order('nama', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
                }

                List data = snapshot.data as List;

                // Filter Pencarian Lokal
                var filteredData = data.where((u) {
                  return u['nama'].toString().toLowerCase().contains(searchQuery);
                }).toList();

                if (filteredData.isEmpty) {
                  return const Center(child: Text("Tidak ada data pengguna"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final user = filteredData[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Text(user['nama'][0].toUpperCase(), 
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(user['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user['email']),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'edit') {
                              // Navigasi ke Edit
                              await Get.to(() => EditPenggunaPage(userData: user));
                              _refreshData();
                            } else if (val == 'delete') {
                              _deleteUser(user);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text("Edit")),
                            const PopupMenuItem(value: 'delete', child: Text("Hapus")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke Tambah
          await Get.to(() => const TambahPenggunaPage());
          _refreshData();
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}