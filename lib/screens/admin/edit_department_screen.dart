import 'package:albaderapp/widgets/department_form.dart';
import 'package:flutter/material.dart';

class EditDepartmentScreen extends StatefulWidget {
  final Map<String, dynamic> department;

  const EditDepartmentScreen({
    super.key,
    required this.department,
  });

  @override
  State<EditDepartmentScreen> createState() => _EditDepartmentScreenState();
}

class _EditDepartmentScreenState extends State<EditDepartmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Department'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DepartmentForm(
          departmentRecord: widget.department,
        ),
      ),
    );
  }
}
