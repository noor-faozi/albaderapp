import 'package:albaderapp/screens/add_holiday_screen.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';

class EditHolidayScreen extends StatefulWidget {
  final Map<String, dynamic> holidayRecord;

  const EditHolidayScreen({super.key, required this.holidayRecord});

  @override
  State<EditHolidayScreen> createState() => _EditHolidayScreenState();
}

class _EditHolidayScreenState extends State<EditHolidayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomSecondaryAppBar(title: "Edit Holiday"),
        body: Padding(
          padding: EdgeInsets.all(screenPadding(context, 0.03)),
          child: Column(
            children: [
              Expanded(
                child: AddHolidayScreen(
                  holidayRecord: widget.holidayRecord,
                ),
              ),
            ],
          ),
        ));
  }
}
