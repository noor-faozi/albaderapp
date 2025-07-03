import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/utils/time_utils.dart';

class OvertimeRecordsScreen extends StatefulWidget {
  const OvertimeRecordsScreen({super.key});

  @override
  State<OvertimeRecordsScreen> createState() => _OvertimeRecordsScreenState();
}

class _OvertimeRecordsScreenState extends State<OvertimeRecordsScreen> {
  final supabase = Supabase.instance.client;

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Stream with optional filter
    final Stream<List<Map<String, dynamic>>> overtimeStream = supabase
        .from('overtime_with_employee')
        .stream(primaryKey: ['id'])
        .order('date')
        .map((event) {
          return (event as List).cast<Map<String, dynamic>>();
        });
    return Scaffold(
      appBar: CustomAppBar(title: 'Overtime'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: overtimeStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: firstColor));
                }

                // Filter overtime by search query (employee ID)
                List<Map<String, dynamic>> overtime = snapshot.data!;

                if (searchQuery.isNotEmpty) {
                  final id = int.tryParse(searchQuery);
                  if (id != null) {
                    overtime =
                        overtime.where((e) => e['employee_id'] == id).toList();
                  } else {
                    overtime = [];
                  }
                }

                return OvertimeDataTableWidget(
                  overtime: overtime,
                  onEdit: (ovt) {
                    // navigate to edit screen
                  },
                  onDelete: (ovt) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: const Text(
                            'Are you sure you want to delete this overtime?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await supabase
                          .from('overtime')
                          .delete()
                          .eq('id', ovt['id']);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// DataTableSource implementation for paginated data table
class OvertimeDataTable extends DataTableSource {
  final List<Map<String, dynamic>> overtime;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  OvertimeDataTable({
    required this.overtime,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= overtime.length) return null;

    final ovt = overtime[index];
    final isHoliday = ovt['holiday_id'] != null;

    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(color: WidgetStateProperty.all(rowColor), cells: [
      DataCell(Text(ovt['employee_id'].toString())),
      DataCell(Text(ovt['employee_name'] ?? '')),
      DataCell(Text(ovt['profession'] ?? '')),
      DataCell(Text(ovt['date']?.toString().split('T').first ?? '')),
      DataCell(Text(TimeUtils.formatTime(ovt['in_time']))),
      DataCell(Text(TimeUtils.formatTime(ovt['out_time']))),
      DataCell(Text(ovt['total_hours'] != null
          ? TimeUtils.formatHoursToHM(ovt['total_hours'])
          : '')),
      DataCell(Text('${(ovt['amount'] ?? 0).toStringAsFixed(4)} AED')),
      DataCell(Text(isHoliday ? 'Holiday' : 'Normal')),
      DataCell(Text(ovt['created_by_name'] ?? '')),
      DataCell(Text(ovt['approved_by_name'] ?? '')),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: gray500),
            onPressed: () => onEdit(ovt),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: gray500),
            onPressed: () => onDelete(ovt),
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => overtime.length;

  @override
  int get selectedRowCount => 0;
}

class OvertimeDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> overtime;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const OvertimeDataTableWidget({
    super.key,
    required this.overtime,
    required this.onEdit,
    required this.onDelete,
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
    _data = OvertimeDataTable(
      overtime: widget.overtime,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant OvertimeDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overtime != widget.overtime) {
      _data = OvertimeDataTable(
        overtime: widget.overtime,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth(context, 0.04),
          vertical: screenHeight(context, 0.02),
        ),
        child: StyledDataTable(
          child: PaginatedDataTable(
            header: const Text('Overtime Records'),
            rowsPerPage: 7,
            columns: const [
              DataColumn(label: Text('Employee ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Profession')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('In Time')),
              DataColumn(label: Text('Out Time')),
              DataColumn(label: Text('Total Hours')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Submitted By')),
              DataColumn(label: Text('Approved By')),
              DataColumn(label: Text('Action')),
            ],
            source: _data,
          ),
        ),
      ),
    );
  }
}
