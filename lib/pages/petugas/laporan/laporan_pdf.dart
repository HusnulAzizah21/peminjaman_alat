import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class LaporanService {
  static Future<void> cetakLaporan(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    try {
      // 1. Hitung Statistik dengan Safety Net
      int totalPinjam = data.length;
      
      // Hitung Terlambat
      int totalTerlambat = data.where((e) {
        if (e['tenggat'] == null) return false;
        try {
          return DateTime.now().isAfter(DateTime.parse(e['tenggat'].toString())) && 
                 e['status_transaksi'] != 'selesai';
        } catch (_) { return false; }
      }).length;

      // Hitung Alat Populer
      Map<String, int> alatCount = {};
      for (var item in data) {
        final details = item['detail_peminjaman'] as List?;
        if (details != null) {
          for (var d in details) {
            String nama = d['alat']?['nama_alat'] ?? "Alat Tidak Diketahui";
            alatCount[nama] = (alatCount[nama] ?? 0) + 1;
          }
        }
      }
      var listAlat = alatCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      String namaAlatPopuler = listAlat.isNotEmpty ? listAlat.first.key : "-";

      // Hitung Hari Teramai
      Map<String, int> hariCount = {};
      for (var item in data) {
        if (item['pengambilan'] != null) {
          try {
            // Kita gunakan id_ID yang sudah di-init di main.dart
            String hari = DateFormat('EEEE', 'id_ID').format(DateTime.parse(item['pengambilan'].toString()));
            hariCount[hari] = (hariCount[hari] ?? 0) + 1;
          } catch (_) {}
        }
      }
      var listHari = hariCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      String namaHariTeramai = listHari.isNotEmpty ? listHari.first.key : "-";

      // 2. Susun Layout PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text("LAPORAN STATISTIK MINGGUAN", 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Box Statistik Ringkasan
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  _buildPdfRow("Total Peminjaman", totalPinjam.toString()),
                  _buildPdfRow("Hari Paling Ramai", namaHariTeramai),
                  _buildPdfRow("Total Terlambat", totalTerlambat.toString()),
                  _buildPdfRow("Alat Terpopuler", namaAlatPopuler),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabel Detail
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1F3C58)),
              headers: ['Peminjam', 'Alat', 'Tanggal', 'Status'],
              data: data.map((item) {
                String namaAlat = "-";
                if (item['detail_peminjaman'] != null && item['detail_peminjaman'].isNotEmpty) {
                  namaAlat = item['detail_peminjaman'][0]['alat']['nama_alat'] ?? "-";
                }
                return [
                  item['users']?['nama'] ?? "-",
                  namaAlat,
                  item['pengambilan'] != null ? DateFormat('dd/MM/yy').format(DateTime.parse(item['pengambilan'])) : "-",
                  item['status_transaksi']?.toString().toUpperCase() ?? "-",
                ];
              }).toList(),
            ),
          ],
        ),
      );

      // 3. Eksekusi Layout (Ini yang memunculkan Preview)
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Peminjaman.pdf',
      );

    } catch (e) {
      debugPrint("Gagal membuat PDF: $e");
    }
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}