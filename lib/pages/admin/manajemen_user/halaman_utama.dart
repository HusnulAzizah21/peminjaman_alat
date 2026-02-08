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
  int totalUsers = 0;

  // Fungsi untuk refresh data secara manual
  void _refreshData() {
    setState(() {});
  }

  // Fungsi untuk menghapus user
  void _deleteUser(Map user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Hapus", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hapus pengguna ${user['nama']}?", style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 5),
            Text("Email: ${user['email'] ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 5),
            Text("Role: ${user['role'] ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              setState(() => isLoading = true);
              
              try {
                await c.supabase.from('users').delete().eq('id_user', user['id_user']);
                Get.snackbar(
                  "Sukses", 
                  "Data berhasil dihapus", 
                  backgroundColor: Colors.green, 
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
                _refreshData();
              } catch (e) {
                Get.snackbar(
                  "Error", 
                  "Gagal menghapus: ${e.toString()}", 
                  backgroundColor: Colors.red, 
                  colorText: Colors.white,
                );
              } finally {
                setState(() => isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan detail user
  void _showUserDetail(Map user) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header dengan avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    (user['nama'] ?? "?")[0].toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['nama'] ?? "Tanpa Nama",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user['email'] ?? "-",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            
            // Detail informasi
            _detailRow("ID User", user['id_user']?.toString() ?? "-"),
            _detailRow("Role", user['role'] ?? "-"),
            _detailRow("Dibuat", _formatDate(user['created_at'])),
            _detailRow("Diperbarui", _formatDate(user['updated_at'])),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.to(() => EditPenggunaPage(userData:));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  "Edit Data",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    try {
      return DateTime.parse(date.toString()).toLocal().toString().split('.')[0];
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manajemen Pengguna", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh",
          ),
        ],
      ),
      drawer: const AdminDrawer(currentPage: 'Manajemen Pengguna'),
      body: Column(
        children: [
          // STATISTIK JUMLAH USER
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: c.supabase
                .from('users')
                .stream(primaryKey: ['id_user'])
                .order('id_user', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                totalUsers = snapshot.data?.length ?? 0;
                
                // Hitung per role
                final adminCount = snapshot.data?.where((u) => u['role'] == 'Admin').length ?? 0;
                final petugasCount = snapshot.data?.where((u) => u['role'] == 'Petugas').length ?? 0;
                final peminjamCount = snapshot.data?.where((u) => u['role'] == 'Peminjam').length ?? 0;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem("Total", totalUsers.toString(), Icons.people),
                      _statItem("Admin", adminCount.toString(), Icons.admin_panel_settings),
                      _statItem("Petugas", petugasCount.toString(), Icons.work),
                      _statItem("Peminjam", peminjamCount.toString(), Icons.person),
                    ],
                  ),
                );
              }
              return Container();
            },
          ),

          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari nama atau email pengguna...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                suffixIcon: searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => searchQuery = ''),
                    )
                  : null,
              ),
            ),
          ),

          // 2. TAB FILTER ROLE
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: ["Semua", "Admin", "Petugas", "Peminjam"].map((role) {
                  bool isSelected = selectedRole == role;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(role, style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : primaryColor,
                      )),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => selectedRole = role);
                      },
                      selectedColor: primaryColor,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? primaryColor : primaryColor.withOpacity(0.2)),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. LIST DATA DARI SUPABASE (REALTIME STREAM)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase
                  .from('users')
                  .stream(primaryKey: ['id_user'])
                  .order('id_user', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          "Terjadi kesalahan: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text("Coba Lagi"),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Memuat data pengguna..."),
                      ],
                    ),
                  );
                }

                // Gunakan list kosong jika snapshot.data null agar tidak error
                final data = snapshot.data ?? [];

                // Filter Lokal dengan proteksi data null
                final filteredData = data.where((u) {
                  // Berikan nilai default "" jika nama atau role null
                  final String name = (u['nama'] ?? "").toString().toLowerCase();
                  final String email = (u['email'] ?? "").toString().toLowerCase();
                  final String role = (u['role'] ?? "").toString();
                  
                  bool matchesRole = selectedRole == 'Semua' || role == selectedRole;
                  bool matchesSearch = name.contains(searchQuery.toLowerCase()) || 
                                       email.contains(searchQuery.toLowerCase());
                  
                  return matchesRole && matchesSearch;
                }).toList();

                if (filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, color: Colors.grey[400], size: 60),
                        const SizedBox(height: 10),
                        Text(
                          searchQuery.isNotEmpty 
                            ? "Tidak ditemukan pengguna dengan kata '$searchQuery'"
                            : "Tidak ada data pengguna",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => searchQuery = ''),
                            child: const Text("Reset Pencarian"),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final user = filteredData[index];
                    
                    // Ambil inisial dengan aman
                    String rawName = user['nama'] ?? "?";
                    String initial = rawName.isNotEmpty ? rawName[0].toUpperCase() : "?";
                    
                    // Tentukan warna berdasarkan role
                    Color roleColor = Colors.grey;
                    if (user['role'] == 'Admin') {
                      roleColor = Colors.red;
                    } else if (user['role'] == 'Petugas') {
                      roleColor = Colors.orange;
                    } else if (user['role'] == 'Peminjam') {
                      roleColor = Colors.green;
                    }

                    return GestureDetector(
                      onTap: () => _showUserDetail(user),
                      child: Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Text(
                              initial, 
                              style: TextStyle(
                                color: primaryColor, 
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            user['nama'] ?? "Tanpa Nama", 
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['email'] ?? "-", 
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: roleColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  user['role'] ?? "Tidak diketahui",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: roleColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (val) {
                              if (val == 'edit') {
                                Get.to(() => EditPenggunaPage(userData: user));
                              } else if (val == 'delete') {
                                _deleteUser(user);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text("Edit"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text("Hapus", style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
      
      // TOMBOL TAMBAH USER
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const TambahPenggunaPage());
          if (result == true) {
            _refreshData();
          }
        },
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _statItem(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 5),
        Text(
          count,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}