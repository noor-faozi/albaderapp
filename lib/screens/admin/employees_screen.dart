import 'package:albaderapp/screens/admin/add_employee_screen.dart';
import 'package:albaderapp/screens/admin/edit_employee_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final supabase = Supabase.instance.client;

  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> _employeeFuture;

  @override
  void initState() {
    super.initState();
    _employeeFuture = fetchEmployeeData();
  }

  Future<List<Map<String, dynamic>>> fetchEmployeeData() async {
    final result =
        await supabase.from('active_employees').select().order('name');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> _refreshData() async {
    setState(() {
      _employeeFuture = fetchEmployeeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Stream<List<Map<String, dynamic>>> employeesStream = supabase
        .from('active_employees')
        .stream(primaryKey: ['id'])
        .order('id')
        .map((event) {
          return (event as List).cast<Map<String, dynamic>>();
        });

    return Scaffold(
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
                future: _employeeFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: firstColor));
                  }

                  // Filter employees by search query (ID)
                  List<Map<String, dynamic>> employees = snapshot.data!;

                  if (searchQuery.isNotEmpty) {
                    final id = int.tryParse(searchQuery);
                    if (id != null) {
                      employees =
                          employees.where((e) => e['id'] == id).toList();
                    } else {
                      employees = [];
                    }
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      EmployeesDataTableWidget(
                        employees: employees,
                        onEdit: (emp) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditEmployeeScreen(
                                employeeRecord: emp,
                              ),
                            ),
                          );
                          _refreshData();
                        },
                        onDelete: (emp) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text(
                                  'Are you sure you want to delete employee ${emp['name']}?'),
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
                            await Supabase.instance.client
                                .from('employees')
                                .update({
                              'deleted_at': DateTime.now().toIso8601String(),
                              'is_active': false,
                            }).eq('id', emp['id']);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Employee deleted successfully (soft delete).'),
                                backgroundColor: Colors.green,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
      ),
    );
  }
}

// DataTableSource implementation for paginated data table
class EmployeesDataTable extends DataTableSource {
  final List<Map<String, dynamic>> employees;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  EmployeesDataTable({
    required this.employees,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= employees.length) return null;

    final emp = employees[index];
    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(color: WidgetStateProperty.all(rowColor), cells: [
      DataCell(Text(emp['id'].toString())),
      DataCell(Text(emp['name'] ?? '')),
      DataCell(Text(emp['profession'] ?? '')),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: gray500),
            onPressed: () => onEdit(emp),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: gray500),
            onPressed: () => onDelete(emp),
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => employees.length;

  @override
  int get selectedRowCount => 0;
}

class EmployeesDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const EmployeesDataTableWidget({
    super.key,
    required this.employees,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<EmployeesDataTableWidget> createState() =>
      _EmployeesDataTableWidgetState();
}

class _EmployeesDataTableWidgetState extends State<EmployeesDataTableWidget> {
  late EmployeesDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = EmployeesDataTable(
      employees: widget.employees,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant EmployeesDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employees != widget.employees) {
      _data = EmployeesDataTable(
        employees: widget.employees,
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
            header: const Text('Active Employees'),
            rowsPerPage: 5,
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Profession')),
              DataColumn(label: Text('Action')), // Added column
            ],
            source: _data,
          ),
        ),
      ),
    );
  }
}
