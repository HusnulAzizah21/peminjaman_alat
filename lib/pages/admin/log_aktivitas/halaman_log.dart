import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../controllers/app_controller.dart';
import '../drawer.dart';

class LogAktivitasPage extends StatefulWidget {
  const LogAktivitasPage({super.key});

  @override
  State<LogAktivitasPage> createState() => _LogAktivitasPageState();
}

class _LogAktivitasPageState extends State<LogAktivitasPage> {
  final c = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: primaryColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text("Log Aktivitas",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ),
      drawer: const AdminDrawer(currentPage: 'Log Aktivitas'),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Cari aktivitas...",
                prefixIcon: Icon(Icons.search, color: primaryColor),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),

          // --- LIST LOG REAL-TIME ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // NOTE: Melakukan query select dengan join ke tabel 'user'
              stream: c.supabase
                  .from('log_aktivitas')
                  .stream(primaryKey: ['id_log'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final data = snapshot.data ?? [];

                // ... bagian import tetap sama ...

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: data.length,
                  // ... di dalam ListView.builder ...
                  itemBuilder: (context, index) {
                    final log = data[index];
                    final String idUser = log['id_user'] ?? "";
                    
                    // Format Tanggal & Waktu (Real-time dari created_at Supabase)
                    final DateTime date = DateTime.parse(log['created_at']).toLocal();
                    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

                    return FutureBuilder<Map<String, dynamic>?>(
                      // Kita ambil 'nama' DAN 'role' sekaligus berdasarkan id_user
                      future: idUser.isEmpty 
                          ? Future.value(null) 
                          : c.supabase.from('users').select('nama, role').eq('id_user', idUser).maybeSingle(),
                      builder: (context, userSnapshot) {
                        // Data User asli dari database
                        String namaPetugas = userSnapshot.data?['nama'] ?? "Memuat...";
                        String roleUser = userSnapshot.data?['role'] ?? "Petugas";
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Notifikasi sesuai desain
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF1F3C58).withOpacity(0.1),
                                    child: const Icon(Icons.notifications, color: Color(0xFF1F3C58), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Judul Aktivitas (Misal: Menambah User)
                                            Text(
                                              log['aktivitas'] ?? "Aktivitas",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                color: Color(0xFF1F3C58), 
                                                fontSize: 14
                                              ),
                                            ),
                                            Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // KETERANGAN: (Nama Asli) Deskripsi
                                        Text(
                                          "($namaPetugas) ${log['keterangan'] ?? ''}",
                                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(thickness: 1),
                              const SizedBox(height: 10),
                              
                              // BADGE: Menampilkan ROLE asli (Admin Master / Petugas / dll)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F3C58), // Background Biru Gelap
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    roleUser, // <--- Ini Role asli dari database
                                    style: const TextStyle(
                                      color: Colors.white, // Teks Putih agar kontras
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }
            )
          ),
        ],
      ),
    );
  }
}