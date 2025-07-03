import 'package:flutter/material.dart';

class OvertimeApprovalCard extends StatelessWidget {
  final Map<String, dynamic> overtime;
  final void Function()? onApprove;

  const OvertimeApprovalCard({
    super.key,
    required this.overtime,
    this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Employee: ${overtime['employee_name']}"),
            Text("Date: ${overtime['date'].toString().split('T').first}"),
            Text("Hours: ${overtime['total_hours']}"),
            Text("Amount: ${overtime['amount']} AED"),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onApprove,
                child: const Text("Approve"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
