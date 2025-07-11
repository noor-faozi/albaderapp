import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
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
        .from('overtime_with_employee')
        .select()
        .isFilter('approved', null)
        .order('date', ascending: false);

    setState(() {
      pendingApprovals = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> approveOvertime(int id) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('overtime').update({
      'approved_by': userId,
      'approved': true,
    }).eq('id', id);

    await fetchPendingOvertime();
  }

  Future<void> rejectOvertime(int id) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('overtime').update({
      'approved_by': userId,
      'approved': false,
    }).eq('id', id);

    await fetchPendingOvertime();
  }

  @override
  void initState() {
    super.initState();
    fetchPendingOvertime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Overtime Approvals"),
      body: pendingApprovals.isEmpty
          ? const Center(child: Text("No pending overtime"))
          : ListView.builder(
              itemCount: pendingApprovals.length,
              itemBuilder: (context, index) {
                final overtime = pendingApprovals[index];
                return OvertimeApprovalCard(
                    overtime: overtime,
                    onApprove: () => approveOvertime(overtime['id']),
                    onReject: () => rejectOvertime(overtime['id']));
              },
            ),
    );
  }
}
