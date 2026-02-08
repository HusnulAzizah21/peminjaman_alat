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
  
  String selectedRole = 'Semua';
  String searchQuery = '';
  bool isLoading = false;
  List<Map<String, dynamic>> usersList = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // 1. Fungsi Load Data (Pusat Refresh)
  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await c.supabase
          .from('users')
          .select('*')
          .order('nama', ascending: true); // Urutkan berdasarkan nama
      
      setState(() {
        usersList = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Error", "Gagal memuat data: $e", 
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // 2. Fungsi Hapus User
  void _deleteUser(Map<String, dynamic> user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Hapus"),
        content: Text("Hapus pengguna ${user['nama']}?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              setState(() => isLoading = true);
              try {
                // Gunakan id_user sesuai struktur tabelmu
                await c.supabase.from('users').delete().eq('id_user', user['id_user']);
                
                // Refresh list setelah hapus
                await _loadUsers(); 
                Get.snackbar("Sukses", "Data berhasil dihapus", 
                    backgroundColor: Colors.green, colorText: Colors.white);
              } catch (e) {
                setState(() => isLoading = false);
                Get.snackbar("Error", "Gagal menghapus: $e", 
                    backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter pencarian dan role secara real-time
    final filteredUsers = usersList.where((user) {
      final String name = (user['nama'] ?? "").toString().toLowerCase();
      final String email = (user['email'] ?? "").toString().toLowerCase();
      final String role = (user['role'] ?? "").toString();
      
      bool matchesRole = selectedRole == 'Semua' || role == selectedRole;
      bool matchesSearch = name.contains(searchQuery.toLowerCase()) || 
                           email.contains(searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manajemen Pengguna", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentPage: 'Manajemen Pengguna'),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: "Cari nama atau email...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // FILTER CHIPS (Role)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: ["Semua", "Admin", "Petugas", "Peminjam"].map((role) {
                bool isSelected = selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedRole = role),
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : primaryColor),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // LIST DATA USER
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUsers,
              child: isLoading && usersList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? const Center(child: Text("Data tidak ditemukan"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  child: Text(user['nama']?[0].toUpperCase() ?? "?", 
                                      style: TextStyle(color: primaryColor)),
                                ),
                                title: Text(user['nama'] ?? "-", 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${user['email']}\nRole: ${user['role']}"),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      // Ambil sinyal 'true' dari EditPenggunaPage
                                      final result = await Get.to(() => EditPenggunaPage(userData: user));
                                      if (result == true) _loadUsers(); 
                                    } else if (val == 'delete') {
                                      _deleteUser(user);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text("Edit")),
                                    const PopupMenuItem(value: 'delete', 
                                        child: Text("Hapus", style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      
      // FLOATING ACTION BUTTON (TAMBAH USER)
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () async {
          // Ambil sinyal 'true' dari TambahPenggunaPage
          final result = await Get.to(() => const TambahPenggunaPage());
          if (result == true) {
            _loadUsers(); // Refresh daftar jika berhasil tambah
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}