import 'package:albaderapp/widgets/custom_app_bar.dart';
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
      appBar: CustomAppBar(title: "Overtime Form"),
      body: const OvertimeForm(),
    );
  }
}
