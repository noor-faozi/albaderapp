import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/widgets/work_order_form.dart'; // adjust path if needed

class EditWorkOrderScreen extends StatefulWidget {
  final Map<String, dynamic> workOrderRecord;

  const EditWorkOrderScreen({
    super.key,
    required this.workOrderRecord,
  });

  @override
  State<EditWorkOrderScreen> createState() => _EditWorkOrderScreenState();
}

class _EditWorkOrderScreenState extends State<EditWorkOrderScreen> {

  @override
  Widget build(BuildContext context) {
    final id = widget.workOrderRecord['id'] ?? '';
    return Scaffold(
      appBar: CustomSecondaryAppBar(title: 'Edit Work Order $id'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: WorkOrderForm(
          workOrderRecord: widget.workOrderRecord,
        ),
      ),
    );
  }
}
