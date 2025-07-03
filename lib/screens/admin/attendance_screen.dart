import 'package:albaderapp/widgets/attendance_form.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
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
      appBar:  CustomAppBar(title: "Attendance Form"),
        body: const AttendanceForm(
    ));
  }
}
