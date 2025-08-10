import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/work_order_form.dart';
import 'package:flutter/material.dart';

class AddWorkOrderScreen extends StatefulWidget {
  const AddWorkOrderScreen({super.key});

  @override
  State<AddWorkOrderScreen> createState() => _AddWorkOrderScreenState();
}

class _AddWorkOrderScreenState extends State<AddWorkOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(
        title: "Add New Work Order",
      ),
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: const Column(
          children: [
            Expanded(
              child: WorkOrderForm(),
            ),
          ],
        ),
      ),
    );
  }
}