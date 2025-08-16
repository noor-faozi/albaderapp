import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/user_form.dart';
import 'package:flutter/material.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> userRecord;

  const EditUserScreen({super.key, required this.userRecord});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Edit User"),
      body: SingleChildScrollView(
        child: UserForm(
          userRecord: widget.userRecord,
        ),
      ),
    );
  }
}
