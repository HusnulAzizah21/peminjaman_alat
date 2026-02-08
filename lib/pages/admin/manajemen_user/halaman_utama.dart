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

  // 1. Fungsi Utama Load Data (Dipanggil berulang kali untuk Refresh)
  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await c.supabase
          .from('users')
          .select('*')
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          usersList = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        Get.snackbar("Error", "Gagal memuat data: $e", backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  // 2. Fungsi Hapus dengan Auto-Refresh
  void _deleteUser(Map<String, dynamic> user) {
    final String idField = _getIdField(user);
    final String userId = user[idField].toString();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Hapus"),
        content: Text("Hapus pengguna ${user['nama']}?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Tutup dialog
              setState(() => isLoading = true);
              try {
                await c.supabase.from('users').delete().eq(idField, userId);
                
                // --- KUNCI REFRESH ---
                await _loadUsers(); 
                
                Get.snackbar("Sukses", "Data berhasil dihapus", backgroundColor: Colors.green, colorText: Colors.white);
              } catch (e) {
                setState(() => isLoading = false);
                Get.snackbar("Error", "Gagal menghapus: $e", backgroundColor: Colors.red, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 3. Helper ID Field
  String _getIdField(Map<String, dynamic> user) {
    if (user.containsKey('id_user')) return 'id_user';
    return 'id';
  }

  @override
  Widget build(BuildContext context) {
    // Filter data di dalam build agar responsif terhadap pencarian & chip
    final filteredUsers = usersList.where((user) {
      final String name = (user['nama'] ?? "").toString().toLowerCase();
      final String email = (user['email'] ?? "").toString().toLowerCase();
      final String role = (user['role'] ?? "").toString();
      
      bool matchesRole = selectedRole == 'Semua' || role == selectedRole;
      bool matchesSearch = name.contains(searchQuery.toLowerCase()) || email.contains(searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manajemen Pengguna", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

          // FILTER CHIPS
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

          // LIST DATA
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUsers, // Tarik bawah untuk refresh manual
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
                                  child: Text(user['nama']?[0].toUpperCase() ?? "?"),
                                ),
                                title: Text(user['nama'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${user['email']}\nRole: ${user['role']}"),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'edit') {
                                      // --- KUNCI REFRESH SETELAH EDIT ---
                                      final result = await Get.to(() => EditPenggunaPage(userData: user));
                                      if (result == true) _loadUsers(); 
                                    } else if (val == 'delete') {
                                      _deleteUser(user);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text("Edit")),
                                    const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
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
      
      // 4. FAB TAMBAH DENGAN AUTO-REFRESH
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 1. Tunggu hasil saat kembali dari halaman tambah
          final result = await Get.to(() => const TambahPenggunaPage());
          
          // 2. Jika result bernilai true, jalankan fungsi load data
          if (result == true) {
            _loadUsers(); 
          }
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}