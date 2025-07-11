import 'package:albaderapp/screens/manager/overtime_approval_screen.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/overtime_data_table_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
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
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: Column(
          children: [
            Center(
              child: CustomButton(
                widthFactor: 0.85,
                heightFactor: 0.12,
                label: 'Approve Records',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OvertimeApprovalScreen()),
                  );
                },
              ),
            ),
            SizedBox(height: screenHeight(context, 0.02)),
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
        ),
      ),
    );
  }
}
