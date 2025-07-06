import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/attendance_form.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';

class EditAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> attendanceRecord;

  const EditAttendanceScreen({super.key, required this.attendanceRecord});

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomSecondaryAppBar(title: "Edit Attendance"),
        body: Padding(
          padding: EdgeInsets.all(screenPadding(context, 0.03)),
          child: Column(
            children: [
              Expanded(
                child: AttendanceForm(attendanceRecord: widget.attendanceRecord,),
              ),
            ],
          ),
        ));
  }
}