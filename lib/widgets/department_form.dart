import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DepartmentForm extends StatefulWidget {
  final Map<String, dynamic>? departmentRecord;
  final VoidCallback? onSuccess;

  const DepartmentForm({
    super.key,
    this.departmentRecord,
    this.onSuccess,
  });

  @override
  State<DepartmentForm> createState() => _DepartmentFormState();
}

class _DepartmentFormState extends State<DepartmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.departmentRecord != null) {
      _nameController.text = widget.departmentRecord!['name'] ?? '';
      _descriptionController.text =
          widget.departmentRecord!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check for duplicates (case-insensitive)
      final existing = await supabase
          .from('departments')
          .select()
          .ilike('name', _nameController.text.trim());

      if (existing.isNotEmpty &&
          (widget.departmentRecord == null ||
              existing.first['id'] != widget.departmentRecord!['id'])) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A department with this name already exists.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (widget.departmentRecord == null) {
        // Insert new department
        await supabase.from('departments').insert({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
        });
      } else {
        // Update existing department
        await supabase.from('departments').update({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
        }).eq('id', widget.departmentRecord!['id']);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.departmentRecord == null
              ? 'Department created successfully.'
              : 'Department updated successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      widget.onSuccess?.call();
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.departmentRecord != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextFormField(
            controller: _nameController,
            labelText: "Department Name",
            prefixIcon: const Icon(Icons.business),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a department name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _descriptionController,
            labelText: "Description (Optional)",
            prefixIcon: const Icon(Icons.description),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
           // Submit button
          Center(
            child: CustomButton(
              label: _isLoading
                  ? 'Loading...'
                  : widget.departmentRecord != null
                      ? 'Update Department'
                      : 'Add Department',
              widthFactor: 0.8,
              heightFactor: 0.1,
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (await showConfirmDialog(
                        context,
                        'Are you sure you want to save this department?',
                      )) {
                        _submitForm();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
