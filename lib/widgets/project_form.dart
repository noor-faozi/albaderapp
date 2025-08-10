import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectForm extends StatefulWidget {
  final Map<String, dynamic>? projectRecord; // For editing

  final void Function()? onSuccess;

  const ProjectForm({
    super.key,
    this.projectRecord,
    this.onSuccess,
  });

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    _idController = TextEditingController();
    _nameController = TextEditingController();
    if (widget.projectRecord != null) {
      final record = widget.projectRecord!;
      _idController.text = record['id']?.toString() ?? '';
      _nameController.text = record['name']?.toString() ?? '';
    }
    super.initState();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final newId = _idController.text.trim();

      if (widget.projectRecord == null) {
        // Check if project ID already exists
        final existing = await supabase
            .from('projects')
            .select('id')
            .eq('id', newId)
            .maybeSingle();

        if (existing != null) {
          // Duplicate ID found, show error and return
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Project ID "$newId" already exists. Please use a different ID.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Insert new project
        await supabase.from('projects').insert({
          'id': newId,
          'name': _nameController.text.trim(),
        });
      } else {
        // Update existing project
        await supabase.from('projects').update(
            {'name': _nameController.text.trim()}).eq('id', newId as Object);
      }

      if (widget.onSuccess != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Project updated successfully.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        widget.onSuccess!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Project saved successfully.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      Navigator.pop(context); // Close form after success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    double padding = screenPadding(context, 0.05);

    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top description
            Text(
              widget.projectRecord == null
                  ? 'Add a new project by filling in the details below.'
                  : 'Update the project details as needed.',
              style: TextStyle(
                fontSize: screenPadding(context, 0.035),
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: screenPadding(context, 0.06)),

            // Project ID label and field
            Padding(
              padding: EdgeInsets.only(bottom: screenPadding(context, 0.03)),
              child: const Text(
                'Project ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            CustomTextFormField(
              controller: _idController,
              isReadOnly: widget.projectRecord != null,
              keyboardType: TextInputType.text,
              labelText: "Project ID",
              prefixIcon: const Icon(Icons.vpn_key),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Project ID is required";
                }
                if (value.trim().length != 3) {
                  return "Project ID must be exactly 3 characters";
                }
                return null;
              },
            ),
            SizedBox(height: screenPadding(context, 0.04)),

            // Project Name label and field
            Padding(
              padding: EdgeInsets.only(bottom: screenPadding(context, 0.03)),
              child: const Text(
                'Project Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            CustomTextFormField(
              controller: _nameController,
              prefixIcon: const Icon(Icons.business),
              labelText: "Project Name",
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Project Name is required";
                }
                return null;
              },
            ),
            SizedBox(height: screenPadding(context, 0.08)),

            // Submit button
            Center(
              child: CustomButton(
                label: _isLoading
                    ? 'Loading...'
                    : widget.projectRecord != null
                        ? 'Update Project'
                        : 'Add Project',
                widthFactor: 0.8,
                heightFactor: 0.1,
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (await showConfirmDialog(
                          context,
                          'Are you sure you want to save this project?',
                        )) {
                          _submitForm();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
