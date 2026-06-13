import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportService {
  static Future<void> generateAttendancePdf({
    required String fullName,
    required String employeeId,
    required List<Map<String, dynamic>> attendanceData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Fetch all selfies if they exist in parallel
    final Map<String, Uint8List> selfieBytesMap = {};
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);

    try {
      await Future.wait(attendanceData.map((item) async {
        final photoUrl = item['photo_url'] as String?;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          try {
            final uri = Uri.parse(photoUrl);
            final request = await client.getUrl(uri);
            final response = await request.close();
            if (response.statusCode == 200) {
              final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
              selfieBytesMap[photoUrl] = Uint8List.fromList(bytes);
            }
          } catch (e) {
            debugPrint('Error fetching selfie: $e');
          }
        }
      }));
    } catch (e) {
      debugPrint('Error in parallel selfie fetching: $e');
    } finally {
      client.close();
    }

    final pdf = pw.Document();
    
    // Format Date Range for Title
    final dateRange = "${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('LAPORAN ABSENSI KARYAWAN',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Pertamina Trans Kontinental (PTK)',
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.PdfLogo(),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Employee Info
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.SizedBox(width: 80, child: pw.Text('Nama')),
                  pw.Text(': $fullName'),
                ]),
                pw.Row(children: [
                  pw.SizedBox(width: 80, child: pw.Text('NIK')),
                  pw.Text(': $employeeId'),
                ]),
                pw.Row(children: [
                  pw.SizedBox(width: 80, child: pw.Text('Periode')),
                  pw.Text(': $dateRange'),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),

            // Attendance Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),    // Tanggal
                1: pw.FlexColumnWidth(1.2),  // Check-In
                2: pw.FlexColumnWidth(1.2),  // Check-Out
                3: pw.FlexColumnWidth(1.2),  // Status Kerja
                4: pw.FlexColumnWidth(1.2),  // Lembur
                5: pw.FlexColumnWidth(1.2),  // Validitas
                6: pw.FlexColumnWidth(1.5),  // Foto Bukti
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Tanggal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Check-In', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Check-Out', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Status Kerja', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Lembur', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Validitas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Foto Bukti', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                // Table Rows
                ...attendanceData.map((item) {
                  final checkInUtc = DateTime.parse(item['check_in_time']).toUtc();
                  final checkInWib = checkInUtc.add(const Duration(hours: 7));
                  final checkOutWib = item['check_out_time'] != null
                      ? DateTime.parse(item['check_out_time']).toUtc().add(const Duration(hours: 7))
                      : null;
                  final overtime = (item['overtime_minutes'] as num?)?.toInt() ?? 0;
                  final photoUrl = item['photo_url'] as String?;

                  pw.Widget photoWidget;
                  if (photoUrl != null && photoUrl.isNotEmpty && selfieBytesMap.containsKey(photoUrl)) {
                    photoWidget = pw.Container(
                      width: 40,
                      height: 50,
                      child: pw.Image(
                        pw.MemoryImage(selfieBytesMap[photoUrl]!),
                        fit: pw.BoxFit.cover,
                      ),
                    );
                  } else {
                    photoWidget = pw.Text('-', style: const pw.TextStyle(fontSize: 9));
                  }

                  return pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(DateFormat('dd MMM yyyy').format(checkInWib), style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(DateFormat('HH:mm').format(checkInWib), style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          checkOutWib != null ? DateFormat('HH:mm').format(checkOutWib) : '-',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(item['work_status'] ?? '-', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(overtime > 0 ? '$overtime menit' : '-', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(item['is_mocked'] == true ? 'Fake GPS' : 'Valid', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: photoWidget),
                      ),
                    ],
                  );
                }),
              ],
            ),

            // Overtime Summary
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Text(
                  'Total Lembur: ${attendanceData.fold<int>(0, (sum, item) {
                    final ot = (item['overtime_minutes'] as num?)?.toInt() ?? 0;
                    return sum + ot;
                  })} menit',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange700),
                ),
              ],
            ),

            pw.SizedBox(height: 28),

            // Footer / Signature Placeholder
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                    pw.SizedBox(height: 60),
                    pw.Container(
                      width: 150,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(width: 1)),
                      ),
                      padding: const pw.EdgeInsets.only(top: 5),
                      child: pw.Center(child: pw.Text('Tanda Tangan Karyawan')),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Show Print Preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Absensi_${fullName.replaceAll(' ', '_')}.pdf',
    );
  }
}
