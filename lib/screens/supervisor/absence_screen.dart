import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/absence_form.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';

class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Absence"),
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: const Column(
          children: [
            Expanded(
              child: AbsenceForm(),
            ),
          ],
        ),
      ),
    );
  }
}
