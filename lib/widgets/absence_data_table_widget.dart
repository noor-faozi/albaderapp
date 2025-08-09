import 'package:albaderapp/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';

class AbsenceDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> absence;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(Map<String, dynamic>)? onDelete;
  final bool showEdit;
  final bool showDelete;
  final bool showAmount;

  const AbsenceDataTableWidget({
    super.key,
    required this.absence,
    this.onEdit,
    this.onDelete,
    this.showEdit = true,
    this.showDelete = true,
    this.showAmount = true,
  });

  @override
  State<AbsenceDataTableWidget> createState() => _AbsenceDataTableWidgetState();
}

class _AbsenceDataTableWidgetState extends State<AbsenceDataTableWidget> {
  late AttendanceDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = _buildDataSource();
  }

  @override
  void didUpdateWidget(covariant AbsenceDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.absence != widget.absence) {
      _data = _buildDataSource();
    }
  }

  AttendanceDataTable _buildDataSource() {
    return AttendanceDataTable(
      absence: widget.absence,
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
      const DataColumn(label: Text('Total Hours')),
      const DataColumn(label: Text('Sick Leave')),
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
            header: const Text('absence Records'),
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
  final List<Map<String, dynamic>> absence;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(Map<String, dynamic>)? onDelete;
  final bool showEdit;
  final bool showDelete;
  final bool showAmount;

  AttendanceDataTable({
    required this.absence,
    this.onEdit,
    this.onDelete,
    required this.showEdit,
    required this.showDelete,
    required this.showAmount,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= absence.length) return null;
    final abs = absence[index];

    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];

    final cells = <DataCell>[
      DataCell(Text(abs['employee_id'].toString())),
      DataCell(Text(abs['employee_name'] ?? '')),
      DataCell(Text(abs['profession'] ?? '')),
      DataCell(Text(abs['date']?.toString().split('T').first ?? '')),
      DataCell(Text(abs['total_hours'] != null
          ? TimeUtils.formatHoursToHM(abs['total_hours'])
          : '')),
      DataCell(Text(abs['is_sickleave'] == true ? 'Yes' : 'No')),
    ];

    if (showAmount) {
      cells.add(
          DataCell(Text('${(abs['amount'] ?? 0).toStringAsFixed(4)} AED')));
    }

    cells.add(DataCell(Text(abs['created_by_name'] ?? '')));

    if (showEdit || showDelete) {
      cells.add(
        DataCell(Row(
          children: [
            if (showEdit && onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey),
                onPressed: () => onEdit!(abs),
              ),
            if (showDelete && onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => onDelete!(abs),
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
  int get rowCount => absence.length;

  @override
  int get selectedRowCount => 0;
}
