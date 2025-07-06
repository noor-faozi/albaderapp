import 'package:albaderapp/screens/admin/attendance_records_screen.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/attendance_form.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceState();
}

class _AttendanceState extends State<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(title: "Attendance"),
        body: Padding(
          padding: EdgeInsets.all(screenPadding(context, 0.03)),
          child: Column(
            children: [
              CustomButton(
                widthFactor: 0.8,
                heightFactor: 0.1,
                label: 'View Records',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AttendanceRecordsScreen()),
                  );
                },
              ),
              SizedBox(height: screenHeight(context, 0.02)),
              const Expanded(
                child: AttendanceForm(),
              ),
            ],
          ),
        ));
  }
}
