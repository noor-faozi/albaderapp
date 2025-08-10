import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkOrderForm extends StatefulWidget {
  final Map<String, dynamic>? workOrderRecord; // For editing
  final void Function()? onSuccess;

  const WorkOrderForm({
    super.key,
    this.workOrderRecord,
    this.onSuccess,
  });

  @override
  State<WorkOrderForm> createState() => _WorkOrderFormState();
}

class _WorkOrderFormState extends State<WorkOrderForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _descriptionController;
  String? _selectedProjectId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    _idController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchProjects();

    if (widget.workOrderRecord != null) {
      final record = widget.workOrderRecord!;
      _idController.text = record['id'] ?? '';
      _descriptionController.text = record['description'] ?? '';
      _selectedProjectId = record['project_id'];
    }
    super.initState();
  }

  Future<void> _fetchProjects() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from('projects').select('id, name');
      setState(() {
        _projects = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Error fetching projects: $e");
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final newId = _idController.text.trim();

      if (widget.workOrderRecord == null) {
        // Check if work order ID already exists
        final existing = await supabase
            .from('work_orders')
            .select('id')
            .eq('id', newId)
            .maybeSingle();

        if (existing != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Work Order ID "$newId" already exists. Please use a different ID.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Insert new work order
        await supabase.from('work_orders').insert({
          'id': newId,
          'description': _descriptionController.text.trim(),
          'project_id': _selectedProjectId,
        });
      } else {
        // Update work order
        await supabase.from('work_orders').update({
          'description': _descriptionController.text.trim(),
          'project_id': _selectedProjectId,
        }).eq('id', newId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.workOrderRecord == null
              ? 'Work Order created successfully.'
              : 'Work Order updated successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      if (widget.onSuccess != null) widget.onSuccess!();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          children: [
            Text(
              widget.workOrderRecord == null
                  ? 'Add a new work order by filling in the details below.'
                  : 'Update the work order details as needed.',
              style: TextStyle(
                fontSize: screenPadding(context, 0.035),
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: screenPadding(context, 0.06)),
            // Project Dropdown
            DropdownButtonFormField<String>(
              value: _selectedProjectId,
              items: _projects
                  .map((proj) => DropdownMenuItem<String>(
                        value: proj['id'],
                        child: Text("${proj['id']} - ${proj['name']}"),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedProjectId = value);
              },
              decoration: InputDecoration(
                  labelText: "Select Project",
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: gray500,
                      width: 1.2,
                    ),
                  )),
              validator: (value) =>
                  value == null ? "Please select a project" : null,
            ),
            SizedBox(height: screenPadding(context, 0.06)),

            // Work Order ID
            CustomTextFormField(
              controller: _idController,
              isReadOnly: widget.workOrderRecord != null,
              labelText: "Work Order ID",
              prefixIcon: const Icon(Icons.confirmation_number),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Work Order ID is required";
                }
                if (value.trim().length != 10) {
                  return "Work Order ID must be exactly 10 characters";
                }
                return null;
              },
            ),
            SizedBox(height: screenPadding(context, 0.06)),

            // Description
            CustomTextFormField(
              controller: _descriptionController,
              labelText: "Description",
              prefixIcon: const Icon(Icons.description),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Description is required";
                }
                return null;
              },
              maxLines: 3,
            ),

            SizedBox(height: screenPadding(context, 0.08)),

            // Submit button
            CustomButton(
              label: _isLoading
                  ? 'Loading...'
                  : widget.workOrderRecord != null
                      ? 'Update Work Order'
                      : 'Add Work Order',
              widthFactor: 0.8,
              heightFactor: 0.1,
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (await showConfirmDialog(
                        context,
                        'Are you sure you want to save this work order?',
                      )) {
                        _submitForm();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
