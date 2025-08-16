import 'package:albaderapp/screens/admin/add_user_screen.dart';
import 'package:albaderapp/screens/admin/edit_user_screen.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/utils/responsive.dart'; 
import 'package:albaderapp/widgets/styled_date_table.dart'; 

class User {
  final String userId; // was 'id' in your model, now 'user_id' in view
  final String
      employeeId; // new field for role-specific id (supervisor/manager id)
  final String username;
  final String fullName;
  final String role;
  final DateTime createdAt;
  final String department;
  final String? departmentId; // optional, UUID string or null

  User({
    required this.userId,
    required this.employeeId,
    required this.username,
    required this.fullName,
    required this.role,
    required this.createdAt,
    required this.department,
    this.departmentId,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as String,
      employeeId: map['id'] as String,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      department: map['department'] as String,
      departmentId: map['department_id'] as String?,
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final supabase = Supabase.instance.client;

  String searchQuery = '';
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
  }

  Future<List<User>> fetchUsers() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      final data = await supabase
          .from('staff_profiles')
          .select()
          .eq('is_active', true)
          .neq('user_id', currentUserId as Object)
          .order('user_id');

      return (data as List).map((e) => User.fromMap(e)).toList();
    } catch (error) {
      throw Exception('Failed to load users: $error');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _usersFuture = fetchUsers();
    });
  }

  Future<Map<String, dynamic>?> fetchUserFullData(String userId) async {
    final supabase = Supabase.instance.client;

    // 1. Get profile
    final profile =
        await supabase.from('profiles').select().eq('id', userId).maybeSingle();

    if (profile == null) return null;

    // 2. Get role from profile
    final role = profile['role'] as String?;

    if (role == null) return profile; // just return profile if no role

    // 3. Fetch extra info from role table
    final tableName = role == 'supervisor' ? 'supervisors' : 'managers';

    final roleData = await supabase
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // 4. Merge profile + roleData
    final fullData = {...profile};
    if (roleData != null) {
      fullData.addAll(roleData);
    }

    return fullData;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Supervisors and Managers"),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenPadding(context, 0.03)),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Username or Full Name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<List<User>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error.toString()}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.blue));
                  }

                  List<User> users = snapshot.data!;
                  if (searchQuery.isNotEmpty) {
                    users = users.where((u) {
                      return u.username.toLowerCase().contains(searchQuery) ||
                          u.fullName.toLowerCase().contains(searchQuery);
                    }).toList();
                  }

                  return UsersDataTableWidget(
                    users: users,
                    onRefresh: _refreshData,
                    onEdit: (User user) async {
                      final fullData = await fetchUserFullData(user.userId);

                      if (fullData == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User profile not found')),
                        );
                        return;
                      }

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditUserScreen(userRecord: fullData),
                        ),
                      );

                      if (result == true) {
                        _refreshData();
                      }
                    },

                    onDelete: (user) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                              'Are you sure you want to delete user ${user.fullName}?'),
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
                          final now = DateTime.now().toIso8601String();
                          // Soft delete from role-specific table
                          final tableName = user.role == 'supervisor'
                              ? 'supervisors'
                              : 'managers';

                          await supabase.from(tableName).update({
                            'deleted_at': now,
                            'is_active': false,
                          }).eq('user_id', user.userId);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('User ${user.fullName} deleted.'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          _refreshData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete user: $e'),
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
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()));
          if (result == true) _refreshData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }
}

class UsersDataTable extends DataTableSource {
  final List<User> users;
  final void Function(User) onEdit;
  final void Function(User) onDelete;

  UsersDataTable({
    required this.users,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;

    final user = users[index];
    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(
      color: WidgetStateProperty.all(rowColor),
      cells: [
        DataCell(Text('${index + 1}')), 
        DataCell(Text(user.username)),
        DataCell(Text(user.fullName)),
        DataCell(Text(user.role)),
        DataCell(Text(
            '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}')),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.grey),
              onPressed: () => onEdit(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.grey),
              onPressed: () => onDelete(user),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}

class UsersDataTableWidget extends StatefulWidget {
  final List<User> users;
  final void Function(User) onEdit;
  final void Function(User) onDelete;
  final Future<void> Function() onRefresh;

  const UsersDataTableWidget({
    super.key,
    required this.users,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<UsersDataTableWidget> createState() => _UsersDataTableWidgetState();
}

class _UsersDataTableWidgetState extends State<UsersDataTableWidget> {
  late UsersDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = UsersDataTable(
      users: widget.users,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant UsersDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      _data = UsersDataTable(
        users: widget.users,
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
              header: const Text('Active Staff'),
              rowsPerPage: 5,
              columns: const [
                DataColumn(label: Text('No.')),
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Full Name')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Created At')),
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
