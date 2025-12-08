import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../utils/csv_mapper.dart';
import '../models/finance_item_model.dart';
import '../database/app_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImportService {
  /// Let user pick CSV, parse it, store rows into DB.
  /// Returns number of inserted rows.
  static Future<int> importCsvAndStore() async {
    // pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return 0;
    final path = result.files.single.path!;
    final file = File(path);
    final content = await file.readAsString();

    final rows = const CsvToListConverter().convert(content, eol: '\n');

    if (rows.isEmpty) return 0;

    // first row should be header — find indices
    final headerRow = rows.first.map((h) => h.toString().toLowerCase().trim()).toList();
    final indexOf = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final h = headerRow[i];
      if (CsvMapper.header.contains(h)) {
        indexOf[h] = i;
      } else {
        // allow some common header variations
        if (h.contains('curr')) indexOf['currency'] = i;
        if (h.contains('amount')) indexOf['amount'] = i;
        if (h.contains('flow')) indexOf['flow'] = i;
        if (h.contains('category')) indexOf['category'] = i;
        if (h.contains('time') || h.contains('date') || h.contains('timestamp')) indexOf['timestamp'] = i;
        if (h == 'id') indexOf['id'] = i;
      }
    }

    // ensure required fields exist (currency, amount, flow, category, timestamp)
    // if timestamp missing, we will set it to now
    // map each data row -> FinanceItemModel
    final dataRows = rows.sublist(1);
    final items = <FinanceItemModel>[];

    for (var row in dataRows) {
      if (row.every((c) => (c == null || c.toString().trim() == ''))) continue; // skip empty rows
      final model = CsvMapper.fromRowWithIndexMap(row as List<dynamic>, indexOf);
      items.add(model);
    }

    if (items.isEmpty) return 0;

    // Insert into DB in a transaction
    final db = await AppDatabase.instance.db;
    await db.transaction((txn) async {
      for (var it in items) {
        // convert model to map for DB insert (timestamp stored as int ms)
        await txn.insert('finance_item', it.toMap());
      }
    });

    return items.length;
  }
}
