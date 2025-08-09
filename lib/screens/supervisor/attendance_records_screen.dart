import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/absence_data_table_widget.dart';
import 'package:albaderapp/widgets/attendance_data_table_widget.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
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
  late Future<List<Map<String, dynamic>>> _absenceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = fetchattendanceData();
    _absenceFuture = fetchAbsenceData();
  }

  Future<List<Map<String, dynamic>>> fetchattendanceData() async {
    final result =
        await supabase.from('attendance_with_employee').select().order('date');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> fetchAbsenceData() async {
    final result = await supabase
        .from('attendance_with_employee')
        .select()
        .eq('is_absent', true)
        .order('date');
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> _refreshData() async {
    setState(() {
      _attendanceFuture = fetchattendanceData();
      _absenceFuture = fetchAbsenceData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(
        title: 'Attendance Records',
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
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
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _attendanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: firstColor));
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

                      return AttendanceDataTableWidget(
                        attendance: attendance,
                        showEdit: false,
                        showDelete: false,
                        showAmount: false,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _absenceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(color: firstColor),
                          ),
                        );
                      }

                      List<Map<String, dynamic>> absence = snapshot.data!;
                      if (searchQuery.isNotEmpty) {
                        final id = int.tryParse(searchQuery);
                        if (id != null) {
                          absence = absence
                              .where((e) => e['employee_id'] == id)
                              .toList();
                        } else {
                          absence = [];
                        }
                      }

                      return AbsenceDataTableWidget(
                        absence: absence,
                        showAmount: false,
                        showDelete: false,
                        showEdit: false,
                      );
                    },
                  )
                ],
              )),
        ),
      ),
    );
  }
}
