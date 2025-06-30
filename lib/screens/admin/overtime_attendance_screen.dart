import 'package:albaderapp/screens/admin/overtime_approval_screen.dart';
import 'package:albaderapp/screens/admin/overtime_records_screen.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/overtime_form.dart';
import 'package:flutter/material.dart';

class OvertimeAttendanceScreen extends StatefulWidget {
  const OvertimeAttendanceScreen({super.key});

  @override
  State<OvertimeAttendanceScreen> createState() => _OvertimeAttendanceState();
}

class _OvertimeAttendanceState extends State<OvertimeAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Overtime Page"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Navigate to view records
                CustomButton(
                  widthFactor: 0.4,
                  heightFactor: 0.1,
                  label: 'View Records',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OvertimeRecordsScreen()),
                    );
                  },
                ),

                // Navigate to approve records
                CustomButton(
                  widthFactor: 0.4,
                  heightFactor: 0.1,
                  label: 'Approve Records',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OvertimeApprovalScreen()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: screenHeight(context, 0.02)),
            const Expanded(
              child: OvertimeForm(),
            ),
          ],
        ),
      ),
    );
  }
}
