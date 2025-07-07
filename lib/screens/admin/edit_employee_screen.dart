import 'package:albaderapp/screens/admin/add_employee_screen.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic> employeeRecord;

  const EditEmployeeScreen({super.key, required this.employeeRecord});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomSecondaryAppBar(title: "Edit Attendance"),
        body: Padding(
          padding: EdgeInsets.all(screenPadding(context, 0.03)),
          child: Column(
            children: [
              Expanded(
                child: AddEmployeeScreen(
                  employeeRecord: widget.employeeRecord,
                ),
              ),
            ],
          ),
        ));
  }
}
