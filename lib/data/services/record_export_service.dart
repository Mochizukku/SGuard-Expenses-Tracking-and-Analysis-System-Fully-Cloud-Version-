import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'record_book_store.dart';

class RecordExportService {
  RecordExportService._();

  static Future<void> exportCurrentSnapshotPdf() async {
    await exportSnapshotPdf(RecordBookStore.buildCurrentSnapshot());
  }

  static Future<void> exportSnapshotPdf(DailyRecordSnapshot snapshot) async {
    final document = pw.Document();
    final overallTotal = snapshot.categories.fold<double>(0.0, (sum, category) => sum + category.total);

    document.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Text('SGuard Spending Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Record date: ${snapshot.dateKey}'),
            pw.Text('Balance: \$${snapshot.balance.toStringAsFixed(2)}'),
            pw.Text('Total spent: \$${overallTotal.toStringAsFixed(2)}'),
            pw.SizedBox(height: 18),
            ...snapshot.categories.map((category) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFCCD6E0)),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(category.name,
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text('\$${category.total.toStringAsFixed(2)}'),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    if (category.items.isEmpty)
                      pw.Text('No records')
                    else
                      pw.TableHelper.fromTextArray(
                        headers: const ['Item', 'Amount', 'Date'],
                        data: category.items
                            .map(
                              (item) => [
                                item.name,
                                item.amount.toStringAsFixed(2),
                                item.date.toIso8601String().split('T').first,
                              ],
                            )
                            .toList(),
                      ),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    final bytes = await document.save();
    await Printing.sharePdf(bytes: bytes, filename: 'sguard-${snapshot.dateKey}.pdf');
  }
}
