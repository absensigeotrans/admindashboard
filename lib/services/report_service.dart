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
              pw.TableHelper.fromTextArray(
                headers: ['Tanggal', 'Check-In', 'Check-Out', 'Status Kerja', 'Lembur', 'Validitas'],
                 data: attendanceData.map((item) {
                   // Parse as UTC time (as stored in database) and convert to WIB (UTC+7)
                   final checkInUtc = DateTime.parse(item['check_in_time']).toUtc();
                   final checkInWib = checkInUtc.add(const Duration(hours: 7));
                   final checkOutWib = item['check_out_time'] != null 
                       ? DateTime.parse(item['check_out_time']).toUtc().add(const Duration(hours: 7)) 
                       : null;
                   final overtime = (item['overtime_minutes'] as num?)?.toInt() ?? 0;
                  
                   return [
                     DateFormat('dd MMM yyyy').format(checkInWib),
                     DateFormat('HH:mm').format(checkInWib),
                     checkOutWib != null ? DateFormat('HH:mm').format(checkOutWib) : '-',
                     item['work_status'] ?? '-',
                     overtime > 0 ? '$overtime menit' : '-',
                     item['is_mocked'] == true ? 'Fake GPS' : 'Valid',
                   ];
                 }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                },
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
