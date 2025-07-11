import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:albaderapp/widgets/date_picker_form_field.dart';
import 'package:albaderapp/widgets/form_card_wrapper.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddHolidayScreen extends StatefulWidget {
  final Map<String, dynamic>? holidayRecord; // For editing
  const AddHolidayScreen({super.key, this.holidayRecord});

  @override
  State<AddHolidayScreen> createState() => _AddHolidayScreenState();
}

class _AddHolidayScreenState extends State<AddHolidayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final String? createdBy = Supabase.instance.client.auth.currentUser?.id;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.holidayRecord != null) {
      _titleController.text = widget.holidayRecord!['title'];
      _descriptionController.text = widget.holidayRecord!['description'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> insertFridayHolidaysManually() async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final createdBy = supabase.auth.currentUser?.id;

    final now = DateTime.now();
    final oneYearLater = DateTime(now.year + 1, now.month, now.day);
    final year = now.year;

    List<DateTime> generateFridays(DateTime start, DateTime end) {
      List<DateTime> fridays = [];
      DateTime date = start;
      while (date.weekday != DateTime.friday) {
        date = date.add(const Duration(days: 1));
      }
      while (!date.isAfter(end)) {
        fridays.add(date);
        date = date.add(const Duration(days: 7));
      }
      return fridays;
    }

    final fridays = generateFridays(now, oneYearLater);
    int insertedCount = 0;

    for (final friday in fridays) {
      // Check if the date already exists
      final existing = await supabase
          .from('holidays')
          .select()
          .eq('date', friday.toIso8601String().substring(0, 10))
          .limit(1)
          .maybeSingle();

      // Insert the new holiday
      if (existing == null) {
        await supabase.from('holidays').insert({
          'date': friday.toIso8601String().substring(0, 10),
          'title': 'Weekly Friday Off',
          'description': 'Regular weekly Friday holiday',
          'created_by': createdBy,
          'is_recurring': true,
        });
        insertedCount++;
      }
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Success and error feedbacks
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(insertedCount == 0
            ? 'No Friday holidays were added.'
            : 'Inserted $insertedCount Friday holidays for one year.'),
        backgroundColor:
            insertedCount == 0 ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> submitHoliday() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final createdBy = supabase.auth.currentUser?.id;
    final formattedDate = _selectedDate.toIso8601String().substring(0, 10);
    final isEditMode = widget.holidayRecord != null;

    try {
      if (isEditMode) {
        // Update existing holiday
        final holidayId = widget.holidayRecord!['id'];

        await supabase.from('holidays').update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
        }).eq('id', holidayId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Holiday updated successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        // Check if the date already exists
        final existing = await supabase
            .from('holidays')
            .select()
            .eq('date', formattedDate)
            .limit(1)
            .maybeSingle();

        if (existing != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('A holiday already exists on that date.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }

        // Insert new holiday
        await supabase.from('holidays').insert({
          'date': formattedDate,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'created_by': createdBy,
          'is_recurring': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Holiday saved successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }

      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.holidayRecord == null
          ? const CustomSecondaryAppBar(title: "Add Holiday")
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenPadding(context, 0.04)),
          child: Form(
            key: _formKey,
            child: FormCardWrapper(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(screenPadding(context, 0.05)),
                    child: const Text(
                      "Add New Holiday",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.7),
                    ),
                  ),
                  DatePickerFormField(
                    selectedDate: _selectedDate,
                    onChanged: (newDate) {
                      setState(() => _selectedDate = newDate);
                    },
                    enabled: widget.holidayRecord == null,
                  ),
                  SizedBox(height: screenHeight(context, 0.03)),
                  CustomTextFormField(
                    controller: _titleController,
                    labelText: "Holiday Title",
                    prefixIcon: const Icon(Icons.celebration),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter a holiday tile";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: screenHeight(context, 0.03)),
                  CustomTextFormField(
                    controller: _descriptionController,
                    labelText: "Description (optional)",
                    maxLines: 2,
                    prefixIcon: const Icon(Icons.note),
                  ),
                  SizedBox(height: screenHeight(context, 0.03)),
                  CustomButton(
                    label: widget.holidayRecord != null
                        ? 'Update Holiday'
                        : 'Add Holiday',
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (await showConfirmDialog(context,
                                'Are you sure you want to submit this record?')) {
                              submitHoliday();
                            }
                          },
                    widthFactor: 0.8,
                    heightFactor: 0.1,
                  ),
                  SizedBox(height: screenHeight(context, 0.03)),
                  if (widget.holidayRecord == null)
                    CustomButton(
                      label: _isLoading
                          ? 'Generating...'
                          : 'Generate Friday Holidays',
                      widthFactor: 0.8,
                      heightFactor: 0.1,
                      onPressed: _isLoading
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Action'),
                                  content: const Text(
                                      'Are you sure you want to generate Friday holidays for one year?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('Cancel',
                                          style: TextStyle(
                                              color: Colors.red[900])),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        insertFridayHolidaysManually();
                                      },
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );
                            },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
