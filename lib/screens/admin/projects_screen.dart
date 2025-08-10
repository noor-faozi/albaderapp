import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/utils/responsive.dart'; // for screenPadding
import 'package:albaderapp/widgets/styled_date_table.dart'; // your StyledDataTable widget
import 'package:albaderapp/screens/admin/edit_project_screen.dart'; // your edit screen
import 'package:albaderapp/screens/admin/add_project_screen.dart'; // your add screen
import 'package:albaderapp/theme/colors.dart'; // your color constants

// Model for Project
class Project {
  final String id;
  final String name;

  Project({required this.id, required this.name});

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }
}

// Main Screen
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final supabase = Supabase.instance.client;

  String searchQuery = '';
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = fetchProjects();
  }

  Future<List<Project>> fetchProjects() async {
    try {
      final data = await supabase.from('projects').select().order('id');
      return (data as List).map((e) => Project.fromMap(e)).toList();
    } catch (error) {
      throw Exception('Failed to load projects: $error');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _projectsFuture = fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: 'Projects'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenPadding(context, 0.03)),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Project ID',
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
              child: FutureBuilder<List<Project>>(
                future: _projectsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error.toString()}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: firstColor));
                  }

                  List<Project> projects = snapshot.data!;
                  if (searchQuery.isNotEmpty) {
                    projects = projects
                        .where((p) => p.id.toUpperCase().contains(searchQuery))
                        .toList();
                  }

                  return ProjectsDataTableWidget(
                    projects: projects,
                    onRefresh: _refreshData,
                    onEdit: (project) async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProjectScreen(projectRecord: {
                            'id': project.id,
                            'name': project.name,
                          }),
                        ),
                      );
                      if (result == true) _refreshData();
                    },
                    onDelete: (project) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                              'Are you sure you want to delete project ${project.name}?'),
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
                              .from('projects')
                              .delete()
                              .eq('id', project.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Project ${project.name} deleted.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _refreshData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete project: $e'),
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
            MaterialPageRoute(builder: (_) => const AddProjectScreen()),
          );
          if (result == true) _refreshData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
  }
}

// DataTableSource for Projects
class ProjectsDataTable extends DataTableSource {
  final List<Project> projects;
  final void Function(Project) onEdit;
  final void Function(Project) onDelete;

  ProjectsDataTable({
    required this.projects,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= projects.length) return null;

    final project = projects[index];
    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(
      color: WidgetStateProperty.all(rowColor),
      cells: [
        DataCell(Text(project.id)),
        DataCell(Text(project.name)),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: gray500),
              onPressed: () => onEdit(project),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: gray500),
              onPressed: () => onDelete(project),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => projects.length;

  @override
  int get selectedRowCount => 0;
}

// Widget to hold the PaginatedDataTable
class ProjectsDataTableWidget extends StatefulWidget {
  final List<Project> projects;
  final void Function(Project) onEdit;
  final void Function(Project) onDelete;
  final Future<void> Function() onRefresh;

  const ProjectsDataTableWidget({
    super.key,
    required this.projects,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh
  });

  @override
  State<ProjectsDataTableWidget> createState() =>
      _ProjectsDataTableWidgetState();
}

class _ProjectsDataTableWidgetState extends State<ProjectsDataTableWidget> {
  late ProjectsDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = ProjectsDataTable(
      projects: widget.projects,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant ProjectsDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects != widget.projects) {
      _data = ProjectsDataTable(
        projects: widget.projects,
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
              header: const Text('Projects'),
              rowsPerPage: 5,
              columns: const [
                DataColumn(label: Text('Project ID')),
                DataColumn(label: Text('Project Name')),
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
