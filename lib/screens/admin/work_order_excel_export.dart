import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> getDownloadFolderPath() async {
  if (Platform.isAndroid) {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
  }
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}


Future<void> exportWorkOrderToExcel(
    Map<String, dynamic> workOrderDetails,
    DateTime fromDate,
    DateTime toDate) async {
  // Ask storage permission
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission denied');
    }
  }

  final excel = Excel.createExcel();
  final sheet = excel['Work Order Report'];

  List<List<dynamic>> allRows = [];

  // --- Work Order Header ---
  allRows.add(['Work Order Report']);
  allRows.add(['Work Order ID', workOrderDetails['workOrderId']]);
  allRows.add(['From Date', fromDate.toIso8601String()]);
  allRows.add(['To Date', toDate.toIso8601String()]);
  allRows.add([]);

  // --- Employee Breakdown ---
  allRows.add(['Employee ID', 'Total Hours', 'Cost']);

  Map<String, dynamic> employees =
      workOrderDetails['employees'] as Map<String, dynamic>;

  employees.forEach((empId, data) {
    allRows.add([
      empId,
      (data['hours'] ?? 0).toStringAsFixed(2),
      (data['cost'] ?? 0).toStringAsFixed(2)
    ]);
  });

  allRows.add([]);
  allRows.add(['Total Hours', workOrderDetails['totalHours'].toStringAsFixed(2)]);
  allRows.add(['Total Cost (AED)', '', workOrderDetails['totalCost'].toStringAsFixed(2)]);

  // --- Add rows to sheet ---
  int currentRow = 0;
  List<int> boldRows = [];

  for (var row in allRows) {
    sheet.appendRow(row);

    if (currentRow == 0 || // Title
        row.isNotEmpty &&
            (row[0].toString().contains('Work Order') ||
             row[0].toString().contains('Employee ID') ||
             row[0].toString().contains('Total'))) {
      boldRows.add(currentRow);
    }

    currentRow++;
  }

  // --- Bold style ---
  final boldStyle = CellStyle(bold: true);
  for (var rowIndex in boldRows) {
    for (int col = 0; col < sheet.maxCols; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.cellStyle = boldStyle;
    }
  }

  // --- Auto column widths ---
  for (int col = 0; col < 10; col++) {
    int maxLength = 0;
    for (var row in allRows) {
      if (row.length > col) {
        final len = row[col]?.toString().length ?? 0;
        if (len > maxLength) maxLength = len;
      }
    }
    if (maxLength > 0) sheet.setColWidth(col, maxLength + 2);
  }

  // --- Save file ---
  final bytes = excel.encode();
  final dirPath = await getDownloadFolderPath();
  final path = '$dirPath/work_order_${workOrderDetails['workOrderId']}.xlsx';

  final file = File(path);
  await file.writeAsBytes(bytes!);

  print("✅ Work order Excel saved at: $path");
}
