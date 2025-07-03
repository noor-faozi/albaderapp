import 'package:albaderapp/widgets/overtime_approval_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OvertimeApprovalScreen extends StatefulWidget {
  const OvertimeApprovalScreen({super.key});

  @override
  State<OvertimeApprovalScreen> createState() => _OvertimeApprovalScreenState();
}

class _OvertimeApprovalScreenState extends State<OvertimeApprovalScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pendingApprovals = [];

  Future<void> fetchPendingOvertime() async {
    final response = await supabase
        .from('overtime_with_employee') // use your view name
        .select()
        .isFilter('approved_by', null);

    setState(() {
      pendingApprovals = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> approveOvertime(int id) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('overtime')
        .update({'approved_by': userId}).eq('id', id);

    await fetchPendingOvertime(); // refresh
  }

  @override
  void initState() {
    super.initState();
    fetchPendingOvertime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Overtime Approvals")),
      body: pendingApprovals.isEmpty
          ? const Center(child: Text("No pending overtime"))
          : ListView.builder(
              itemCount: pendingApprovals.length,
              itemBuilder: (context, index) {
                final overtime = pendingApprovals[index];
                return OvertimeApprovalCard(
                  overtime: overtime,
                  onApprove: () => approveOvertime(overtime['id']),
                );
              },
            ),
    );
  }
}
