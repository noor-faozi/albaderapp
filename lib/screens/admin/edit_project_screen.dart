import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/widgets/project_form.dart'; // Your reusable form widget
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> projectRecord;

  const EditProjectScreen({super.key, required this.projectRecord});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Edit Project"),
      body: SingleChildScrollView(
        child: ProjectForm(
          projectRecord: widget.projectRecord,
        ),
      ),
    );
  }
}
