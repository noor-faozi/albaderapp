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
  // Request permission
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission denied');
    }
  }

  final excel = Excel.createExcel();
  final sheet = excel['Project Report'];

  sheet.appendRow(['Project ID', 'From Date', 'To Date']);
  sheet.appendRow(
      [projectId, fromDate.toIso8601String(), toDate.toIso8601String()]);
  sheet.appendRow([]);
  sheet.appendRow(['Work Order ID', 'Labour Cost']);

  double total = 0.0;
  for (var wo in workOrders) {
    sheet.appendRow([wo['workOrderId'], wo['cost']]);
    total += wo['cost'];
  }

  sheet.appendRow([]);
  sheet.appendRow(['Total Cost', total]);

  final bytes = excel.encode();

  final dirPath = await getDownloadFolderPath();
  final path =
      '$dirPath/project_labour_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  final file = File(path);
  await file.writeAsBytes(bytes!);
}
