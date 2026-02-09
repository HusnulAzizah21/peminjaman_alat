import 'package:aplikasi_peminjamanbarang/pages/admin/log_aktivitas/halaman_log.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

  // --- LOGIKA GRAFIK: PROSES DATA DARI SUPABASE ---
  List<double> _processWeeklyData(List<Map<String, dynamic>> data) {
    List<double> counts = List.filled(7, 0.0);
    for (var item in data) {
      if (item['pengambilan'] != null) {
        try {
          DateTime date = DateTime.parse(item['pengambilan'].toString());
          // weekday: Senin=1...Minggu=7. Ubah ke index 0-6
          int dayIndex = date.weekday - 1;
          counts[dayIndex] += 1;
        } catch (e) {
          debugPrint("Error parse tanggal grafik: $e");
        }
      }
    }
    return counts;
  }

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
        title: Text("Dashboard Admin",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
      ),
      drawer: const AdminDrawer(currentPage: 'Beranda'),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // --- ROW 1: STATS CARDS (Real-time dari tabel Alat) ---
              StreamBuilder(
                stream: c.supabase.from('alat').stream(primaryKey: ['id_alat']),
                builder: (context, snapshot) {
                  int total = 0, tersedia = 0, dipinjam = 0;
                  if (snapshot.hasData) {
                    total = snapshot.data!.length;
                    tersedia = snapshot.data!.where((e) => (e['stok_total'] ?? 0) > 0).length;
                    dipinjam = snapshot.data!.where((e) => e['status'] == 'Dipinjam').length;
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard("Total Alat", total.toString(), Icons.inventory_2, Colors.blueGrey),
                      _buildStatCard("Tersedia", tersedia.toString(), Icons.check_circle, Colors.green),
                      _buildStatCard("Dipinjam", dipinjam.toString(), Icons.swap_horiz, Colors.red),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),
              Text("Tren Peminjaman Mingguan", 
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
              const SizedBox(height: 15),

              // --- ROW 2: GRAFIK (Real-time dari tabel Peminjaman) ---
              Container(
                height: 200,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: c.supabase.from('peminjaman').stream(primaryKey: ['id_peminjaman']),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    List<double> weeklyData = _processWeeklyData(snapshot.data!);
                    return _buildWeeklyChart(weeklyData);
                  },
                ),
              ),

              const SizedBox(height: 25),
              
              // --- ROW 3: AKTIVITAS TERBARU HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Aktivitas Peminjaman Terbaru", 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Get.to(() => const LogAktivitasPage()),
                    child: Text("Lihat Log", style: TextStyle(color: primaryColor, fontSize: 12)),
                  ),
                ],
              ),

              // --- ROW 4: AKTIVITAS TERBARU LIST (Real-time) ---
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: c.supabase
                    .from('peminjaman')
                    .stream(primaryKey: ['id_peminjaman'])
                    .order('pengambilan', ascending: false)
                    .limit(5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text("Belum ada transaksi")),
                    );
                  }
                  return Column(
                    children: snapshot.data!.map((item) => _buildRecentActivityItem(item)).toList(),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: STAT CARD ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: CHART ---
  Widget _buildWeeklyChart(List<double> data) {
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal < 5 ? 5 : maxVal + 2,
        barTouchData: BarTouchData(enabled: true),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                const days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                return Text(days[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
            ),
          ),
        ),
        barGroups: List.generate(7, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: data[i], color: primaryColor, width: 15, borderRadius: BorderRadius.circular(4))],
        )),
      ),
    );
  }

  // --- WIDGET HELPER: ACTIVITY ITEM (REAL DATA) ---
  Widget _buildRecentActivityItem(Map<String, dynamic> item) {
    String status = item['status_transaksi'] ?? 'pending';
    Color statusColor = status == 'selesai' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(status == 'selesai' ? Icons.check : Icons.timer, color: statusColor, size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Transaksi #${item['id_peminjaman']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text("Status: ${status.toUpperCase()}", style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['pengambilan'] != null 
                    ? DateFormat('dd MMM').format(DateTime.parse(item['pengambilan'])) 
                    : "-",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const Text("Peminjaman", style: TextStyle(fontSize: 9, color: Colors.blueGrey)),
            ],
          ),
        ],
      ),
    );
  }
}