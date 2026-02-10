import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../controllers/app_controller.dart';
import '../drawer.dart';
import '../../admin/data_peminjaman/halaman_utama.dart';

class AdminBerandaPage extends StatefulWidget {
  const AdminBerandaPage({super.key});

  @override
  State<AdminBerandaPage> createState() => _AdminBerandaPageState();
}

class _AdminBerandaPageState extends State<AdminBerandaPage> {
  final c = Get.find<AppController>();
  final Color primaryColor = const Color(0xFF1F3C58);

  // ────────────────────────────────────────────────
  // 1. Proses data mingguan untuk grafik
  // ────────────────────────────────────────────────
  List<double> _processWeeklyData(List<Map<String, dynamic>> data) {
    List<double> counts = List.filled(7, 0.0);
    for (var item in data) {
      if (item['pengambilan'] != null) {
        try {
          DateTime date = DateTime.parse(item['pengambilan'].toString());
          int dayIndex = date.weekday - 1; // Senin=1 → index 0
          counts[dayIndex] += 1;
        } catch (e) {
          debugPrint("Error parse tanggal grafik: $e");
        }
      }
    }
    return counts;
  }

  // ────────────────────────────────────────────────
  // 2. Ambil semua data alat untuk statistik
  // ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchAlat() async {
    try {
      final response = await c.supabase.from('alat').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetch alat: $e');
      return [];
    }
  }

  // ────────────────────────────────────────────────
  // 3. Ambil 5 peminjaman terbaru (real-time via stream)
  // ────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> _streamRecentPeminjaman() {
    return c.supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .order('pengambilan', ascending: false)
        .limit(5);
  }

  // ────────────────────────────────────────────────
  // 4. Ambil data peminjaman untuk grafik mingguan (real-time)
  // ────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> _streamPeminjamanChart() {
    return c.supabase
        .from('peminjaman')
        .stream(primaryKey: ['id_pinjam'])
        .order('pengambilan', ascending: true);
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
        title: Text(
          "Dashboard Admin",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
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

              // ────────────────────────────────────────────────
              // STAT CARDS (Total Alat, Tersedia, Dipinjam)
              // ────────────────────────────────────────────────
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchAlat(),
                builder: (context, snapshot) {
                  int total = 0, tersedia = 0, dipinjam = 0;

                  if (snapshot.hasData) {
                    total = snapshot.data!.length;
                    tersedia = snapshot.data!
                        .where((e) => (e['stok_total'] ?? 0) > 0)
                        .length;
                    dipinjam = snapshot.data!
                        .where((e) => (e['stok_total'] ?? 0) == 0)
                        .length;
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

              // ────────────────────────────────────────────────
              // JUDUL & GRAFIK TREN MINGGUAN (real-time)
              // ────────────────────────────────────────────────
              Text(
                "Tren Peminjaman Mingguan",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 15),

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
                  stream: _streamPeminjamanChart(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final weeklyData = _processWeeklyData(snapshot.data ?? []);
                    return _buildWeeklyChart(weeklyData);
                  },
                ),
              ),

              const SizedBox(height: 25),

              // ────────────────────────────────────────────────
              // HEADER AKTIVITAS TERBARU
              // ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Aktivitas Peminjaman Terbaru",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Get.to(() => const AdminDataPeminjamanPage()),
                    child: Text(
                      "Lihat Log",
                      style: TextStyle(color: primaryColor, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ────────────────────────────────────────────────
              // AKTIVITAS TERBARU (real-time, limit 5)
              // ────────────────────────────────────────────────
              SizedBox(
                height: 320,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _streamRecentPeminjaman(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Belum ada transaksi"));
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        return _buildRecentActivityItem(item);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // HELPER WIDGETS
  // ────────────────────────────────────────────────

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

  Widget _buildWeeklyChart(List<double> data) {
    double maxVal = data.isEmpty ? 5 : data.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal < 5 ? 5 : (maxVal + (maxVal * 0.2)),
        barTouchData: BarTouchData(enabled: true),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: const Text("(jumlah alat yang dipinjam)", style: TextStyle(fontSize: 10, color: Colors.grey)),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text("(hari dalam 1 minggu)", style: TextStyle(fontSize: 10, color: Colors.grey)),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val < 0 || val > 5) return const SizedBox();
                const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[val.toInt()],
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          6,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: i < data.length ? data[i] : 0,
                color: primaryColor,
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(Map<String, dynamic> item) {
    String userId = item['id_peminjam']?.toString() ?? '-';
    String waktu = '-';
    if (item['pengambilan'] != null) {
      try {
        final dt = DateTime.parse(item['pengambilan']);
        waktu = DateFormat('dd MMM yyyy • HH:mm').format(dt);
      } catch (_) {}
    }

    String title = "Peminjaman Barang";
    String subtitle = "User ID: $userId";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(waktu, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text("Peminjaman", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}