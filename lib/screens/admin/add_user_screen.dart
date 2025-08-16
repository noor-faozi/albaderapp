import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/user_form.dart';
import 'package:flutter/material.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(
        title: "Add New User",
      ),
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: const Column(
          children: [
            Expanded(
              child: UserForm(),
            ),
          ],
        ),
      ),
    );
  }
}