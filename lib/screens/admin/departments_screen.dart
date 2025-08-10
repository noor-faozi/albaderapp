import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/theme/colors.dart';
import 'add_department_screen.dart';
import 'edit_department_screen.dart';

class Department {
  final String id;
  final String name;
  final String? description;

  Department({required this.id, required this.name, this.description});

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }
}

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final supabase = Supabase.instance.client;
  String searchQuery = '';
  late Future<List<Department>> _departmentsFuture;

  @override
  void initState() {
    super.initState();
    _departmentsFuture = fetchDepartments();
  }

  Future<List<Department>> fetchDepartments() async {
    try {
      final data = await supabase.from('departments').select().order('id');
      return (data as List).map((e) => Department.fromMap(e)).toList();
    } catch (error) {
      throw Exception('Failed to load departments: $error');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _departmentsFuture = fetchDepartments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: 'Departments'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenPadding(context, 0.03)),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Department ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim().toUpperCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<List<Department>>(
                future: _departmentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error.toString()}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: firstColor));
                  }

                  List<Department> departments = snapshot.data!;
                  if (searchQuery.isNotEmpty) {
                    departments = departments
                        .where((d) => d.id.toUpperCase().contains(searchQuery))
                        .toList();
                  }

                  return DepartmentsDataTableWidget(
                    departments: departments,
                    onRefresh: _refreshData,
                    onEdit: (dept) async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditDepartmentScreen(
                            department: {
                              'id': dept.id,
                              'name': dept.name,
                              'description': dept.description,
                            },
                          ),
                        ),
                      );
                      if (result == true) _refreshData();
                    },
                    onDelete: (dept) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                              'Are you sure you want to delete department ${dept.name}?'),
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
                        try {
                          await supabase
                              .from('departments')
                              .delete()
                              .eq('id', dept.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Department ${dept.name} deleted successfully.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _refreshData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete department: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDepartmentScreen()),
          );
          if (result == true) _refreshData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Department'),
      ),
    );
  }
}

class DepartmentsDataTable extends DataTableSource {
  final List<Department> departments;
  final void Function(Department) onEdit;
  final void Function(Department) onDelete;

  DepartmentsDataTable({
    required this.departments,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= departments.length) return null;

    final dept = departments[index];
    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(
      color: WidgetStateProperty.all(rowColor),
      cells: [
        DataCell(Text(dept.name)),
        DataCell(Text(dept.description ?? '-')),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: gray500),
              onPressed: () => onEdit(dept),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: gray500),
              onPressed: () => onDelete(dept),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => departments.length;

  @override
  int get selectedRowCount => 0;
}

class DepartmentsDataTableWidget extends StatefulWidget {
  final List<Department> departments;
  final void Function(Department) onEdit;
  final void Function(Department) onDelete;
  final Future<void> Function() onRefresh;

  const DepartmentsDataTableWidget({
    super.key,
    required this.departments,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<DepartmentsDataTableWidget> createState() =>
      _DepartmentsDataTableWidgetState();
}

class _DepartmentsDataTableWidgetState
    extends State<DepartmentsDataTableWidget> {
  late DepartmentsDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = DepartmentsDataTable(
      departments: widget.departments,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant DepartmentsDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.departments != widget.departments) {
      _data = DepartmentsDataTable(
        departments: widget.departments,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenPadding(context, 0.03),
            vertical: screenPadding(context, 0.02),
          ),
          child: StyledDataTable(
            child: PaginatedDataTable(
              header: const Text('Departments'),
              rowsPerPage: 5,
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Actions')),
              ],
              source: _data,
            ),
          ),
        ),
      ),
    );
  }
}
