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
                CustomButton(
                  label: 'View Records',
                  onPressed: () {
                    // Your logic here
                  },
                ),
                CustomButton(
                  label: 'Approve Records',
                  onPressed: () {
                    // Your logic here
                  },
                ),
              ],
            ),
            SizedBox(height: screenHeight(context, 0.04)),
            const Expanded(
              child: OvertimeForm(),
            ),
          ],
        ),
      ),
    );
  }
}
