import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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

Future<void> exportProjectReportToExcel({
  required String projectId,
  required DateTime fromDate,
  required DateTime toDate,
  required List<Map<String, dynamic>> workOrders,
}) async {
  // Request storage permission
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
    if (!status.isGranted) throw Exception('Storage permission denied');
  }

  final excel = Excel.createExcel();
  final sheet = excel['Project Report'];

  List<List<dynamic>> allRows = [];

  // --- Project Header ---
  allRows.add(['Project ID', 'From Date', 'To Date']);
  allRows
      .add([projectId, fromDate.toIso8601String(), toDate.toIso8601String()]);
  allRows.add([]); // empty row

  double projectTotal = 0.0;

  // --- Work Orders ---
  for (var wo in workOrders) {
    allRows.add(['Work Order', wo['workOrderId']]);
    allRows.add(['Employee ID', 'Total Hours', 'Cost']);

    (wo['employees'] as Map<String, dynamic>).forEach((empId, data) {
      allRows.add([empId, data['hours'], data['cost']]);
    });

    allRows.add([]); // empty row
    allRows.add(['Work Order Total Hours', wo['totalHours']]);
    allRows.add(['Work Order Total Cost', '', wo['totalCost']]);
    allRows.add([]); // empty row

    projectTotal += wo['totalCost'];
  }

  // --- Project Total ---
  allRows.add(['Project Total Cost', '', projectTotal]);

  // --- Append rows to sheet ---
  int currentRow = 0;
  List<int> boldRows = [];

  for (var row in allRows) {
    sheet.appendRow(row);

    // Mark bold rows
    if (currentRow == 0 || // Project header
        row.isNotEmpty &&
            (row[0].toString().contains('Work Order') ||
                row[0].toString().contains('Employee ID') ||
                row[0].toString().contains('Total'))) {
      boldRows.add(currentRow);
    }

    currentRow++;
  }

  // --- Apply bold style ---
  final boldStyle = CellStyle(bold: true);
  for (var rowIndex in boldRows) {
    for (int col = 0; col < sheet.maxCols; col++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.cellStyle = boldStyle;
    }
  }

  // --- Auto-adjust column widths ---
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

  // --- Save Excel file ---
  final bytes = excel.encode();
  final dirPath = await getDownloadFolderPath();
  final path =
      '$dirPath/project_labour_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  final file = File(path);
  await file.writeAsBytes(bytes!);

  print('Excel report saved at: $path');
}
