import 'package:albaderapp/screens/admin/overtime_records_screen.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/overtime_data_table_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _overtimeFuture = fetchovertimeData();
  }

  Future<List<Map<String, dynamic>>> fetchovertimeData() async {
    final result =
        await supabase.from('overtime_with_employee').select().order('date');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> _refreshData() async {
    setState(() {
      _overtimeFuture = fetchovertimeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(
        title: 'Overtime Records',
      ),
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(screenPadding(context, 0.03)),
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<Map<String, dynamic>> overtime = snapshot.data!;

                      if (searchQuery.isNotEmpty) {
                        final id = int.tryParse(searchQuery);
                        if (id != null) {
                          overtime = overtime
                              .where((e) => e['employee_id'] == id)
                              .toList();
                        } else {
                          overtime = [];
                        }
                      }

                      return OvertimeDataTableWidget(
                        overtime: overtime,
                        showEdit: false,
                        showDelete: false,
                        showAmount: false,
                        showApproval: true,
                      );
                    },
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
