import 'package:albaderapp/screens/admin/edit_attendance_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/utils/time_utils.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceRecordsScreen extends StatefulWidget {
  const AttendanceRecordsScreen({super.key});

  @override
  State<AttendanceRecordsScreen> createState() =>
      _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  final supabase = Supabase.instance.client;

  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = fetchAttendanceData();
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceData() async {
    final result =
        await supabase.from('attendance_with_employee').select().order('date');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> _refreshData() async {
    setState(() {
      _attendanceFuture = fetchAttendanceData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Attendance Records"),
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
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(child: Text('Error: ${snapshot.error}')),
                      ],
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: firstColor),
                    );
                  }

                  List<Map<String, dynamic>> attendance = snapshot.data!;

                  if (searchQuery.isNotEmpty) {
                    final id = int.tryParse(searchQuery);
                    if (id != null) {
                      attendance = attendance
                          .where((e) => e['employee_id'] == id)
                          .toList();
                    } else {
                      attendance = [];
                    }
                  }

                  return ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      OvertimeDataTableWidget(
                        attendance: attendance,
                        onEdit: (atd) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditAttendanceScreen(
                                attendanceRecord:
                                    atd, // <- pass full record map
                              ),
                            ),
                          );
                          _refreshData();
                        },
                        onDelete: (atd) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text(
                                  'Are you sure you want to delete this attendance record?'),
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
                                .from('attendance')
                                .delete()
                                .eq('id', atd['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'attendance record deleted successfully!'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                            _refreshData();
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// DataTableSource implementation for paginated data table
class AttendanceDataTable extends DataTableSource {
  final List<Map<String, dynamic>> attendance;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  AttendanceDataTable({
    required this.attendance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= attendance.length) return null;

    final atd = attendance[index];
    final isHoliday = atd['holiday_id'] != null;

    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(color: WidgetStateProperty.all(rowColor), cells: [
      DataCell(Text(atd['employee_id'].toString())),
      DataCell(Text(atd['employee_name'] ?? '')),
      DataCell(Text(atd['profession'] ?? '')),
      DataCell(Text(atd['date']?.toString().split('T').first ?? '')),
      DataCell(Text(atd['work_order_id'] ?? '')),
      DataCell(Text(TimeUtils.formatTime(atd['in_time']))),
      DataCell(Text(TimeUtils.formatTime(atd['out_time']))),
      DataCell(Text(atd['total_hours'] != null
          ? TimeUtils.formatHoursToHM(atd['total_hours'])
          : '')),
      DataCell(Text('${(atd['amount'] ?? 0).toStringAsFixed(4)} AED')),
      DataCell(Text(atd['created_by_name'] ?? '')),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: gray500),
            onPressed: () => onEdit(atd),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: gray500),
            onPressed: () => onDelete(atd),
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => attendance.length;

  @override
  int get selectedRowCount => 0;
}

class OvertimeDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> attendance;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const OvertimeDataTableWidget({
    super.key,
    required this.attendance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<OvertimeDataTableWidget> createState() =>
      _AttendanceDataTableWidgetState();
}

class _AttendanceDataTableWidgetState extends State<OvertimeDataTableWidget> {
  late AttendanceDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = AttendanceDataTable(
      attendance: widget.attendance,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant OvertimeDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendance != widget.attendance) {
      _data = AttendanceDataTable(
        attendance: widget.attendance,
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
            header: const Text('Attendance Records'),
            rowsPerPage: 7,
            columns: const [
              DataColumn(label: Text('Employee ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Profession')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('W/O ID')),
              DataColumn(label: Text('In Time')),
              DataColumn(label: Text('Out Time')),
              DataColumn(label: Text('Total Hours')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Supervisor')),
              DataColumn(label: Text('Action')),
            ],
            source: _data,
          ),
        ),
      ),
    );
  }
}
