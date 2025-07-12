import 'package:albaderapp/screens/admin/attendance_records_screen.dart';
import 'package:albaderapp/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';

class AttendanceDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> attendance;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(Map<String, dynamic>)? onDelete;
  final bool showEdit;
  final bool showDelete;
  final bool showAmount;

  const AttendanceDataTableWidget({
    super.key,
    required this.attendance,
    this.onEdit,
    this.onDelete,
    this.showEdit = true,
    this.showDelete = true,
    this.showAmount = true,
  });

  @override
  State<AttendanceDataTableWidget> createState() =>
      _AttendanceDataTableWidgetState();
}

class _AttendanceDataTableWidgetState extends State<AttendanceDataTableWidget> {
  late AttendanceDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = _buildDataSource();
  }

  @override
  void didUpdateWidget(covariant AttendanceDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendance != widget.attendance) {
      _data = _buildDataSource();
    }
  }

  AttendanceDataTable _buildDataSource() {
    return AttendanceDataTable(
      attendance: widget.attendance,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      showEdit: widget.showEdit,
      showDelete: widget.showDelete,
      showAmount: widget.showAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = <DataColumn>[
      const DataColumn(label: Text('Employee ID')),
      const DataColumn(label: Text('Name')),
      const DataColumn(label: Text('Profession')),
      const DataColumn(label: Text('Date')),
      const DataColumn(label: Text('W/O ID')),
      const DataColumn(label: Text('In Time')),
      const DataColumn(label: Text('Out Time')),
      const DataColumn(label: Text('Total Hours')),
    ];

    if (widget.showAmount) {
      columns.add(const DataColumn(label: Text('Amount')));
    }

    columns.add(
      const DataColumn(label: Text('Supervisor')),
    );

    if (widget.showEdit || widget.showDelete) {
      columns.add(const DataColumn(label: Text('Action')));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: StyledDataTable(
          child: PaginatedDataTable(
            header: const Text('Attendance Records'),
            rowsPerPage: 7,
            columns: columns,
            source: _data,
          ),
        ),
      ),
    );
  }
}

class AttendanceDataTable extends DataTableSource {
  final List<Map<String, dynamic>> attendance;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(Map<String, dynamic>)? onDelete;
  final bool showEdit;
  final bool showDelete;
  final bool showAmount;

  AttendanceDataTable({
    required this.attendance,
    this.onEdit,
    this.onDelete,
    required this.showEdit,
    required this.showDelete,
    required this.showAmount,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= attendance.length) return null;
    final ovt = attendance[index];

    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];

    final cells = <DataCell>[
      DataCell(Text(ovt['employee_id'].toString())),
      DataCell(Text(ovt['employee_name'] ?? '')),
      DataCell(Text(ovt['profession'] ?? '')),
      DataCell(Text(ovt['date']?.toString().split('T').first ?? '')),
      DataCell(Text(ovt['work_order_id'] ?? '')),
      DataCell(Text(TimeUtils.formatTime(ovt['in_time']))),
      DataCell(Text(TimeUtils.formatTime(ovt['out_time']))),
      DataCell(Text(ovt['total_hours'] != null
          ? TimeUtils.formatHoursToHM(ovt['total_hours'])
          : '')),
    ];

    if (showAmount) {
      cells.add(
          DataCell(Text('${(ovt['amount'] ?? 0).toStringAsFixed(4)} AED')));
    }

    cells.add(DataCell(Text(ovt['created_by_name'] ?? '')));

    if (showEdit || showDelete) {
      cells.add(
        DataCell(Row(
          children: [
            if (showEdit && onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => onEdit!(ovt),
              ),
            if (showDelete && onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => onDelete!(ovt),
              ),
          ],
        )),
      );
    }

    return DataRow(
      color: WidgetStateProperty.all(rowColor),
      cells: cells,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => attendance.length;

  @override
  int get selectedRowCount => 0;
}
