import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/utils/time_utils.dart';
import 'package:albaderapp/widgets/custom_button.dart';
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
        padding: EdgeInsets.all(screenWidth(context, 0.06)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildBoldText(
                    "Employee ID: ",
                    overtime['employee_id'].toString(),
                  ),
                ),
                Expanded(
                  child: _buildBoldText(
                    "Employee Name: ",
                    overtime['employee_name'] ?? '',
                  ),
                ),
              ],
            ),
            _buildBoldText(
              "Date: ",
              overtime['date'].toString().split('T').first,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildBoldText("Time In: ", TimeUtils.formatTime(overtime['in_time'])),
                ),
                Expanded(
                  child:
                      _buildBoldText("Time Out: ", TimeUtils.formatTime(overtime['out_time'])),
                ),
              ],
            ),
            _buildBoldText("Hours: ", overtime['total_hours'].toString()),
            _buildBoldText("Submitted By: ",
                "${(overtime['created_by_name'])} "),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: CustomButton(
                label: "Approve",
                onPressed: onApprove,
                widthFactor: 0.25,
                heightFactor: 0.08,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoldText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
            ),
          ],
        ),
      ),
    );
  }
}
