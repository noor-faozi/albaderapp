import 'package:albaderapp/screens/admin/edit_overtime_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/widgets/overtime_data_table_widget.dart'; // make sure this path is correct

class OvertimeRecordsScreen extends StatefulWidget {
  const OvertimeRecordsScreen({super.key});

  @override
  State<OvertimeRecordsScreen> createState() => _OvertimeRecordsScreenState();
}

class _OvertimeRecordsScreenState extends State<OvertimeRecordsScreen> {
  final supabase = Supabase.instance.client;
  String searchQuery = '';
  late Future<List<Map<String, dynamic>>> _overtimeFuture;

  @override
  void initState() {
    super.initState();
    _overtimeFuture = fetchOvertimeData();
  }

  Future<List<Map<String, dynamic>>> fetchOvertimeData() async {
    final result =
        await supabase.from('overtime_with_employee').select().order('date');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> _refreshData() async {
    setState(() {
      _overtimeFuture = fetchOvertimeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: 'Overtime Records'),
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
                future: _overtimeFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: firstColor),
                    );
                  }

                  List<Map<String, dynamic>> overtime = snapshot.data!;

                  if (searchQuery.isNotEmpty) {
                    final id = int.tryParse(searchQuery);
                    overtime = id != null
                        ? overtime.where((e) => e['employee_id'] == id).toList()
                        : [];
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      OvertimeDataTableWidget(
                        overtime: overtime,
                        onEdit: (ovt) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditOvertimeScreen(overtimeRecord: ovt),
                            ),
                          ).then((_) => _refreshData());
                        },
                        onDelete: (ovt) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text(
                                  'Are you sure you want to delete this overtime record?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await supabase
                                .from('overtime')
                                .delete()
                                .eq('id', ovt['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Overtime record deleted successfully.'),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                            _refreshData();
                          }
                        },
                        showEdit: true,
                        showDelete: true,
                        showAmount: true,
                        showApproval: true,
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
