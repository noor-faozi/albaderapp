import 'package:albaderapp/screens/supervisor/overtime_records_screen.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/overtime_form.dart';
import 'package:flutter/material.dart';

class OvertimeScreen extends StatefulWidget {
  const OvertimeScreen({super.key});

  @override
  State<OvertimeScreen> createState() => _OvertimeScreenState();
}

class _OvertimeScreenState extends State<OvertimeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(screenPadding(context, 0.03)),
        child: Column(
          children: [
            CustomButton(
              widthFactor: 0.8,
              heightFactor: 0.1,
              label: 'View Records',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OvertimeRecordsScreen()),
                );
              },
            ),
            SizedBox(height: screenHeight(context, 0.02)),
            const Expanded(
              child: OvertimeForm(),
            ),
          ],
        ),
      ),
    );
  }
}
