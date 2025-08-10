import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/project_form.dart';
import 'package:flutter/material.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(
        title: "Add New Project",
      ),
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: const Column(
          children: [
            Expanded(
              child: ProjectForm(),
            ),
          ],
        ),
      ),
    );
  }
}
