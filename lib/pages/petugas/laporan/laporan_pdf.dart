import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// ────────────────────────────────────────────────
/// SERVICE utama untuk menghasilkan laporan PDF statistik peminjaman
/// ────────────────────────────────────────────────
class LaporanService {
  static Future<void> cetakLaporanMingguan({
    required List<Map<String, dynamic>> dataPeminjaman,
    String judulLaporan = "LAPORAN STATISTIK MINGGUAN",
  }) async {
    final generator = LaporanPdfGenerator(data: dataPeminjaman, judul: judulLaporan);
    await generator.generateAndPrint();
  }
}

/// ────────────────────────────────────────────────
/// Kelas yang bertanggung jawab membangun isi dokumen PDF
/// ────────────────────────────────────────────────
class LaporanPdfGenerator {
  final List<Map<String, dynamic>> data;
  final String judul;
  final pw.Document pdf = pw.Document();

  LaporanPdfGenerator({
    required this.data,
    required this.judul,
  });

  /// Method utama: generate PDF dan tampilkan preview print
  Future<void> generateAndPrint() async {
    try {
      _buildDocument();
      await _printPdf();
    } catch (e, stack) {
      debugPrint("Gagal membuat PDF: $e\n$stack");
    }
  }

  /// Membangun seluruh struktur dokumen PDF
  void _buildDocument() {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildStatistikRingkasan(),
          pw.SizedBox(height: 30),
          _buildTabelDetailPeminjaman(),
        ],
      ),
    );
  }

  /// Bagian header laporan
  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          judul,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.SizedBox(height: 12),
      ],
    );
  }

  /// Bagian kotak statistik ringkasan
  pw.Widget _buildStatistikRingkasan() {
    final stats = _hitungStatistik();

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _StatRow(label: "Total Peminjaman", value: stats.totalPeminjaman.toString()),
          _StatRow(label: "Hari Paling Ramai", value: stats.hariTeramai),
          _StatRow(label: "Total Terlambat", value: stats.totalTerlambat.toString()),
          _StatRow(label: "Alat Terpopuler", value: stats.alatPopuler),
        ],
      ),
    );
  }

  /// Tabel daftar detail peminjaman
  pw.Widget _buildTabelDetailPeminjaman() {
    return pw.TableHelper.fromTextArray(
      headers: ['Peminjam', 'Alat', 'Tanggal Pinjam', 'Status'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1F3C58)),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
      },
      data: data.map((item) {
        final namaPeminjam = item['users']?['nama']?.toString() ?? '-';
        final namaAlat = _ambilNamaAlatPertama(item) ?? '-';
        final tanggal = _formatTanggal(item['pengambilan']);
        final status = (item['status_transaksi']?.toString() ?? '-').toUpperCase();

        return [namaPeminjam, namaAlat, tanggal, status];
      }).toList(),
    );
  }

  /// ────────────────────────────────────────────────
  /// Perhitungan statistik (dipisah agar mudah di-test & di-maintain)
  /// ────────────────────────────────────────────────
  _LaporanStats _hitungStatistik() {
    // Total peminjaman
    final totalPinjam = data.length;

    // Total terlambat (hanya yang belum selesai dan melewati tenggat)
    final totalTerlambat = data.where((e) {
      final tenggatStr = e['tenggat']?.toString();
      if (tenggatStr == null) return false;
      try {
        final tenggat = DateTime.parse(tenggatStr);
        return DateTime.now().isAfter(tenggat) &&
               e['status_transaksi'] != 'selesai';
      } catch (_) {
        return false;
      }
    }).length;

    // Alat terpopuler
    final alatCount = <String, int>{};
    for (var item in data) {
      final details = item['detail_peminjaman'] as List?;
      if (details != null) {
        for (var d in details) {
          final nama = d['alat']?['nama_alat']?.toString() ?? "Alat Tidak Diketahui";
          alatCount[nama] = (alatCount[nama] ?? 0) + (d['jumlah'] as num? ?? 1).toInt();
        }
      }
    }
    final alatSorted = alatCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final alatPopuler = alatSorted.isNotEmpty ? alatSorted.first.key : "-";

    // Hari paling ramai
    final hariCount = <String, int>{};
    final formatter = DateFormat('EEEE', 'id_ID');
    for (var item in data) {
      final tglStr = item['pengambilan']?.toString();
      if (tglStr != null) {
        try {
          final hari = formatter.format(DateTime.parse(tglStr));
          hariCount[hari] = (hariCount[hari] ?? 0) + 1;
        } catch (_) {}
      }
    }
    final hariSorted = hariCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hariTeramai = hariSorted.isNotEmpty ? hariSorted.first.key : "-";

    return _LaporanStats(
      totalPeminjaman: totalPinjam,
      totalTerlambat: totalTerlambat,
      alatPopuler: alatPopuler,
      hariTeramai: hariTeramai,
    );
  }

  /// Helper: ambil nama alat pertama dari detail_peminjaman
  String? _ambilNamaAlatPertama(Map<String, dynamic> item) {
    final details = item['detail_peminjaman'] as List?;
    if (details == null || details.isEmpty) return null;
    return details.first['alat']?['nama_alat']?.toString();
  }

  /// Helper: format tanggal aman
  String _formatTanggal(dynamic value) {
    if (value == null) return "-";
    try {
      return DateFormat('dd/MM/yy').format(DateTime.parse(value.toString()));
    } catch (_) {
      return "-";
    }
  }

  /// Cetak / preview PDF
  Future<void> _printPdf() async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Statistik_Peminjaman.pdf',
    );
  }
}

/// ────────────────────────────────────────────────
/// Model sederhana untuk menyimpan hasil perhitungan statistik
/// ────────────────────────────────────────────────
class _LaporanStats {
  final int totalPeminjaman;
  final int totalTerlambat;
  final String alatPopuler;
  final String hariTeramai;

  _LaporanStats({
    required this.totalPeminjaman,
    required this.totalTerlambat,
    required this.alatPopuler,
    required this.hariTeramai,
  });
}

/// ────────────────────────────────────────────────
/// Widget baris statistik di dalam PDF
/// ────────────────────────────────────────────────
class _StatRow extends pw.StatelessWidget {
  final String label;
  final String value;

  _StatRow({required this.label, required this.value});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}