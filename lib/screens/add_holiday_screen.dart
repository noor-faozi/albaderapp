import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddHolidayScreen extends StatefulWidget {
  const AddHolidayScreen({super.key});

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
      final existing = await supabase
          .from('holidays')
          .select()
          .eq('date', friday.toIso8601String().substring(0, 10))
          .limit(1)
          .maybeSingle();

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Add Holiday"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(screenPadding(context, 0.05)),
                  child: const Text(
                    "Add New Holiday",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                FormField<DateTime>(
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Date:',
                              style: TextStyle(fontSize: 16),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDate = date;
                                    field.didChange(date); // update form state
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _selectedDate
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                            child: Text(
                              field.errorText!,
                              style:
                                  const TextStyle(color: darkRed, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: screenHeight(context, 0.03)),
                CustomTextFormField(
                  controller: _titleController,
                  labelText: "Holiday Title",
                  prefixIcon: const Icon(Icons.celebration),
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
                  label:
                      _isLoading ? 'Generating...' : 'Generate Friday Holidays',
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // close dialog first
                                    insertFridayHolidaysManually(); // starts the task
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
    );
  }
}
