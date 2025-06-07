import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class Employees extends StatefulWidget {
  const Employees({super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        appBar: CustomAppBar(
      title: "Employees Attendance",
    ));
  }
}
