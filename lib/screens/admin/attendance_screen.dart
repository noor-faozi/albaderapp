import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceState();
}

class _AttendanceState extends State<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin AttendanceScreen'));
  }
}