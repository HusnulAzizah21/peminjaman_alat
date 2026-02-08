import 'package:aplikasi_peminjamanbarang/pages/admin/log_aktivitas/halaman_log.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart'; // Pastikan sudah install package fl_chart
import '../../../../controllers/app_controller.dart';
import '../drawer.dart';

class AdminBerandaPage extends StatefulWidget {
  const AdminBerandaPage({super.key});

  @override
  State<AdminBerandaPage> createState() => _AdminBerandaPageState();
}

class _AdminBerandaPageState extends State<AdminBerandaPage> {
  final c = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);

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
        title: Text("Beranda",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ),
      drawer: const AdminDrawer(currentPage: 'Beranda'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // --- STATS CARDS (REAL-TIME) ---
            StreamBuilder(
              stream: c.supabase.from('alat').stream(primaryKey: ['id_alat']),
              builder: (context, snapshot) {
                int totalAlat = 0;
                int alatTersedia = 0;
                int alatDipinjam = 0;

                if (snapshot.hasData) {
                  totalAlat = snapshot.data!.length;
                  // Logika: Tersedia jika stok > 0, Dipinjam jika status tertentu atau stok berkurang
                  // Sesuaikan dengan struktur kolom database kamu
                  alatTersedia = snapshot.data!.where((e) => (e['stok_total'] ?? 0) > 0).length;
                  alatDipinjam = snapshot.data!.where((e) => (e['status'] == 'Dipinjam')).length; 
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard("Total Alat", totalAlat.toString(), Icons.inventory_2, Colors.blueGrey),
                    _buildStatCard("Alat Tersedia", alatTersedia.toString(), Icons.check_circle, Colors.green),
                    _buildStatCard("Sedang Dipinjam", alatDipinjam.toString(), Icons.swap_horiz, Colors.red),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),
            Text("Grafik Peminjaman Mingguan", 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 15),

            // --- CHART CONTAINER ---
            Container(
              height: 250,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: _buildWeeklyChart(),
            ),

            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Aktivitas terbaru", 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Get.to(() => const LogAktivitasPage()),
                  style: TextButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  child: const Row(
                    children: [
                      Text("Detail", style: TextStyle(color: Colors.white, fontSize: 10)),
                      Icon(Icons.arrow_right_alt, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),

            // --- RECENT ACTIVITIES (REAL-TIME) ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: c.supabase.from('log_aktivitas').stream(primaryKey: ['id_log']).limit(5).order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                return Column(
                  children: snapshot.data!.map((log) => _buildActivityItem(log)).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Simulasi data 7 hari terakhir. Untuk data real, lakukan query count grouped by day di Supabase.
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 100),
          _makeGroupData(1, 80),
          _makeGroupData(2, 60),
          _makeGroupData(3, 40),
          _makeGroupData(4, 20),
          _makeGroupData(5, 10),
          _makeGroupData(6, 5),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: primaryColor, width: 20, borderRadius: BorderRadius.circular(4))],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(Icons.notifications, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['nama_user'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(log['aktivitas'] ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
            child: const Text("Petugas", style: TextStyle(color: Colors.white, fontSize: 9)),
          )
        ],
      ),
    );
  }
}