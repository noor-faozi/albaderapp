import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/utils/time_utils.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class OvertimeApprovalCard extends StatelessWidget {
  final Map<String, dynamic> overtime;
  final void Function()? onApprove;
  final void Function()? onReject; 

  const OvertimeApprovalCard({
    super.key,
    required this.overtime,
    this.onApprove,
    this.onReject, 
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
              "W/O ID: ",
              overtime['work_order_id'] ?? '',
            ),
            _buildBoldText(
              "Date: ",
              overtime['date'].toString().split('T').first,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildBoldText(
                      "Time In: ", TimeUtils.formatTime(overtime['in_time'])),
                ),
                Expanded(
                  child: _buildBoldText(
                      "Time Out: ", TimeUtils.formatTime(overtime['out_time'])),
                ),
              ],
            ),
            _buildBoldText("Total Hours: ",
                TimeUtils.formatHoursToHM(overtime['total_hours'])),
            _buildBoldText("Manager: ", "${(overtime['created_by_name'])} "),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomButton(
                    label: "Reject",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Action'),
                          content: const Text(
                              'Are you sure you want to reject this overtime record?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onReject?.call();
                              },
                              child: const Text('Confirm',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    widthFactor: 0.25,
                    heightFactor: 0.08,
                    textColor: Colors.red[900],
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    label: "Approve",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Action'),
                          content: const Text(
                              'Are you sure you want to approve this overtime record?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onApprove?.call();
                              },
                              child: const Text('Confirm',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    widthFactor: 0.25,
                    heightFactor: 0.08,
                    textColor: Colors.green[900],
                  ),
                ],
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
