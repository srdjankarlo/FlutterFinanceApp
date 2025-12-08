import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/finance_item_model.dart';
import '../utils/csv_mapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ExportService {
  /// Export CSV and return the saved File
  static Future<File> exportCsv(List<FinanceItemModel> items, {String? filename}) async {
    final rows = <List<dynamic>>[];
    rows.add(CsvMapper.header);
    for (var it in items) {
      rows.add(CsvMapper.toRow(it));
    }
    final csvString = const ListToCsvConverter().convert(rows);

    final dir = await _getSaveDirectory();
    final name = filename ?? 'finance_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$name');
    return file.writeAsString(csvString);
  }

  /// Export PDF and return the saved File
  static Future<File> exportPdf(List<FinanceItemModel> items, {String? filename}) async {
    final pdf = pw.Document();

    final tableData = <List<String>>[];
    for (var it in items) {
      tableData.add([
        it.id?.toString() ?? '',
        it.currency,
        it.amount.toString(),
        it.flow,
        it.category,
        DateTime.fromMillisecondsSinceEpoch(it.timestamp.millisecondsSinceEpoch).toIso8601String(),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(level: 0, child: pw.Text('Finance Report', style: pw.TextStyle(fontSize: 22))),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['id', 'currency', 'amount', 'flow', 'category', 'timestamp'],
              data: tableData,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await _getSaveDirectory();
    final name = filename ?? 'finance_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$name');
    return file.writeAsBytes(bytes);
  }

  /// Try to use Downloads on Android, otherwise app documents dir.
  static Future<Directory> _getSaveDirectory() async {
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          final downloads = Directory('/storage/emulated/0/Download');
          if (await downloads.exists()) return downloads;
        }
      } catch (_) {}
    }
    return await getApplicationDocumentsDirectory();
  }
}
