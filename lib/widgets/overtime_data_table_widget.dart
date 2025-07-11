import 'package:albaderapp/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/widgets/styled_date_table.dart'; // make sure this is the correct path

class OvertimeDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> overtime;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(Map<String, dynamic>)? onDelete;
  final bool showEdit;
  final bool showDelete;
  final bool showAmount;
  final bool showApproval;

  const OvertimeDataTableWidget({
    super.key,
    required this.overtime,
    this.onEdit,
    this.onDelete,
    this.showEdit = true,
    this.showDelete = true,
    this.showAmount = true,
    this.showApproval = true,
  });

  @override
  State<OvertimeDataTableWidget> createState() =>
      _OvertimeDataTableWidgetState();
}

class _OvertimeDataTableWidgetState extends State<OvertimeDataTableWidget> {
  late OvertimeDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = _buildDataSource();
  }

  @override
  void didUpdateWidget(covariant OvertimeDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overtime != widget.overtime) {
      _data = _buildDataSource();
    }
  }

  OvertimeDataTable _buildDataSource() {
    return OvertimeDataTable(
      overtime: widget.overtime,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      showEdit: widget.showEdit,
      showDelete: widget.showDelete,
      showAmount: widget.showAmount,
      showApproval: widget.showApproval,
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

    columns.add(const DataColumn(label: Text('Type')));

    if (widget.showApproval) {
      columns.add(const DataColumn(label: Text('Approved')));
    }

    columns.addAll([
      const DataColumn(label: Text('Supervisor')),
      const DataColumn(label: Text('Manager')),
    ]);

    if (widget.showEdit || widget.showDelete) {
      columns.add(const DataColumn(label: Text('Action')));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: StyledDataTable(
          child: PaginatedDataTable(
            header: const Text('Overtime Records'),
            rowsPerPage: 7,
            columns: columns,
            source: _data,
          ),
        ),
      ),
    );
  }
}

class OvertimeDataTable extends DataTableSource {
  final List<Map<String, dynamic>> overtime;
  final void Function(Map<String, dynamic>)? onEdit;
  final void Function(Map<String, dynamic>)? onDelete;
  final bool showEdit;
  final bool showDelete;
  final bool showAmount;
  final bool showApproval;

  OvertimeDataTable({
    required this.overtime,
    this.onEdit,
    this.onDelete,
    required this.showEdit,
    required this.showDelete,
    required this.showAmount,
    required this.showApproval,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= overtime.length) return null;
    final ovt = overtime[index];
    final isHoliday = ovt['holiday_id'] != null;

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

    cells.add(DataCell(Text(isHoliday ? 'Holiday' : 'Normal')));

    if (showApproval) {
      cells.add(
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ovt['approved'] == true
                  ? Colors.green[100]
                  : ovt['approved'] == false
                      ? Colors.red[100]
                      : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ovt['approved'] == true
                  ? 'Approved'
                  : ovt['approved'] == false
                      ? 'Not Approved'
                      : 'Pending',
              style: TextStyle(
                color: ovt['approved'] == true
                    ? Colors.green[800]
                    : ovt['approved'] == false
                        ? Colors.red[800]
                        : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    cells.add(DataCell(Text(ovt['created_by_name'] ?? '')));
    cells.add(DataCell(Text(ovt['approved_by_name'] ?? '')));

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
  int get rowCount => overtime.length;

  @override
  int get selectedRowCount => 0;
}
