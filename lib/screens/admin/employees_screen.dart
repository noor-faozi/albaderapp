import 'package:albaderapp/screens/admin/add_employee_screen.dart';
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

  // Pagination params
  static const int rowsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    // Stream with optional filter
    final Stream<List<Map<String, dynamic>>> employeesStream = supabase
        .from('employees')
        .stream(primaryKey: ['id'])
        .order('id')
        .map((event) {
          return (event as List).cast<Map<String, dynamic>>();
        });

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
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
              stream: employeesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter employees by search query (ID)
                List<Map<String, dynamic>> employees = snapshot.data!;

                if (searchQuery.isNotEmpty) {
                  final id = int.tryParse(searchQuery);
                  if (id != null) {
                    employees = employees.where((e) => e['id'] == id).toList();
                  } else {
                    employees = [];
                  }
                }

                return EmployeesDataTableWidget(
                  employees: employees,
                  onEdit: (emp) {
                    // navigate to edit screen
                  },
                  onDelete: (emp) {
                    // show delete confirmation
                  },
                );
              },
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
    return DataRow(cells: [
      DataCell(Text(emp['id'].toString())),
      DataCell(Text(emp['name'] ?? '')),
      DataCell(Text(emp['profession'] ?? '')),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => onEdit(emp),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
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
      child: PaginatedDataTable(
        header: const Text('Employees'),
        rowsPerPage: 10,
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Profession')),
          DataColumn(label: Text('Action')), // Added column
        ],
        source: _data,
      ),
    );
  }
}
