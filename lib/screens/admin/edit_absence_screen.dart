import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/absence_form.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';

class EditAbsenceScreen extends StatefulWidget {
  final Map<String, dynamic> absenceRecord;

  const EditAbsenceScreen({super.key, required this.absenceRecord});

  @override
  State<EditAbsenceScreen> createState() => _EditAbsenceScreenState();
}

class _EditAbsenceScreenState extends State<EditAbsenceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomSecondaryAppBar(title: "Edit Absence"),
        body: Padding(
          padding: EdgeInsets.all(screenPadding(context, 0.03)),
          child: Column(
            children: [
              Expanded(
                child: AbsenceForm(
                  absenceRecord: widget.absenceRecord,
                ),
              ),
            ],
          ),
        ));
  }
}
