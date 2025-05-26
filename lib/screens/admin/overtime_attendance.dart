import 'package:flutter/material.dart';

class OvertimeAttendance extends StatefulWidget {
  const OvertimeAttendance({super.key});

  @override
  State<OvertimeAttendance> createState() => _OvertimeAttendanceState();
}

class _OvertimeAttendanceState extends State<OvertimeAttendance> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin overtime'));
  }
}