import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/department_form.dart';
import 'package:flutter/material.dart';

class AddDepartmentScreen extends StatefulWidget {
  const AddDepartmentScreen({super.key});

  @override
  State<AddDepartmentScreen> createState() => _AddDepartmentScreenState();
}

class _AddDepartmentScreenState extends State<AddDepartmentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(
        title: "Add New Department",
      ),
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: const Column(
          children: [
            Expanded(
              child: DepartmentForm(),
            ),
          ],
        ),
      ),
    );
  }
}