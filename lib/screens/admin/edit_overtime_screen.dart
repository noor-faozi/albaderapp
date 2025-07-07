import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/overtime_form.dart';
import 'package:flutter/material.dart';

class EditOvertimeScreen extends StatefulWidget {
  final Map<String, dynamic> overtimeRecord;

  const EditOvertimeScreen({super.key, required this.overtimeRecord});

  @override
  State<EditOvertimeScreen> createState() => _EditOvertimeScreenState();
}

class _EditOvertimeScreenState extends State<EditOvertimeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomSecondaryAppBar(title: "Edit Overtime"),
        body: Padding(
          padding: EdgeInsets.all(screenPadding(context, 0.03)),
          child: Column(
            children: [
              Expanded(
                child: OvertimeForm(
                  overtimeRecord: widget.overtimeRecord,
                ),
              ),
            ],
          ),
        ));
  }
}
