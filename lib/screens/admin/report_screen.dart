import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportsState();
}

class _ReportsState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin ReportScreen'));
  }
}