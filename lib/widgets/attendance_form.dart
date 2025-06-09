import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceForm extends StatefulWidget {
  // final String createdByRole;
  final void Function()? onSubmitSuccess;

  const AttendanceForm({
    super.key,
    // required this.createdByRole,
    this.onSubmitSuccess,
  });

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final _employeeIdController = TextEditingController();
  final _inTimeController = TextEditingController();
  final _outTimeController = TextEditingController();

  Map<String, dynamic>? _employee;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  // List<dynamic> _woOptions = [];
  String? _selectedWoId;
  String? _dateError;
  bool _employeeNotFound = false;

  double? get _totalHours {
    if (_inTime == null || _outTime == null) return null;
    final inDateTime = DateTime(0, 0, 0, _inTime!.hour, _inTime!.minute);
    final outDateTime = DateTime(0, 0, 0, _outTime!.hour, _outTime!.minute);
    final diff = outDateTime.difference(inDateTime);
    return diff.inMinutes / 60.0;
  }

  Future<void> _fetchEmployee() async {
    final id = _employeeIdController.text.trim();
    final result =
        await supabase.from('employees').select().eq('id', id).maybeSingle();
    setState(() {
      _employee = result;
      _employeeNotFound = result == null;
    });
  }


  // Future<void> _loadWorkOrders() async {
  //   final result = await supabase.from('work_orders').select();
  //   setState(() => _woOptions = result);
  // }

  @override
  void initState() {
    super.initState();
    // _loadWorkOrders();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selectedDateOnly.isAfter(today)) {
      setState(() {
        _dateError = 'Date cannot be in the future';
      });
      return;
    } else {
      setState(() {
        _dateError = null;
      });
    }

    if (_employee == null ||
        _inTime == null ||
        _outTime == null ||
        _selectedWoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final data = {
      'employee_id': _employee!['id'],
      'date': _selectedDate.toIso8601String(),
      // 'wo_id': _selectedWoId,
      'in_time': '${_inTime!.hour}:${_inTime!.minute}',
      'out_time': '${_outTime!.hour}:${_outTime!.minute}',
      'total_hours': _totalHours,
      // 'created_by_role': widget.createdByRole,
    };

    await supabase.from('attendance').insert(data);

    widget.onSubmitSuccess?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance submitted')),
    );
  }

  String formatHoursToHM(double hours) {
    final int h = hours.floor();
    final int m = ((hours - h) * 60).round();
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final verticalPadding = screenPadding(context, 0.015); // For field height
    final buttonHeight = screenPadding(context, 0.08); // For button height

    return Padding(
      padding: EdgeInsets.all(screenPadding(context, 0.06)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              FormField<DateTime>(
                validator: (value) {
                  if (_selectedDate.isAfter(DateTime.now())) {
                    return 'Date cannot be in the future';
                  }
                  return null;
                },
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
                              _selectedDate.toLocal().toString().split(' ')[0],
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
              SizedBox(height: screenHeight(context, 0.025)),
          
             Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _employeeIdController,
                      decoration: InputDecoration(
                        labelText: 'Employee Code',
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: verticalPadding,
                          horizontal: screenPadding(context, 0.025),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter employee code'
                          : null,
                    ),
                  ),
                  SizedBox(width: screenPadding(context, 0.02)),
                  SizedBox(
                    height: buttonHeight,
                    child: CustomButton(
                      label: 'Search',
                      onPressed: _fetchEmployee,
                    ),
                  ),
                ],
              ),
          
          
              if (_employee != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenPadding(context, 0.05)),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(screenPadding(context, 0.04)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Employee Details",
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Text("Name: ${_employee!['name']}"),
                            Text("Profession: ${_employee!['profession']}"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (_employeeNotFound) ...[
                Padding(
                  padding: EdgeInsets.all(screenPadding(context, 0.05)),
                  child: const Text(
                    'No employee found with this code.',
                    style:
                        TextStyle(color: red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
          
          
              SizedBox(height: screenHeight(context, 0.025)),
          
              // DropdownButtonFormField(
              //   items: _woOptions
              //       .map<DropdownMenuItem<String>>((wo) => DropdownMenuItem(
              //             value: wo['id'],
              //             child: Text(wo['title']),
              //           ))
              //       .toList(),
              //   onChanged: (value) => _selectedWoId = value,
              //   decoration: const InputDecoration(labelText: 'Work Order'),
              //   validator: (value) => value == null ? 'Select a WO' : null,
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Clock in Time:',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _inTime ?? TimeOfDay.now(),
                      );
                      if (time != null) setState(() => _inTime = time);
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _inTime == null ? 'Select Time' : _inTime!.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
          
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Clock out Time:',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _outTime ?? TimeOfDay.now(),
                      );
                      if (time != null) setState(() => _outTime = time);
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _outTime == null
                          ? 'Select Time'
                          : _outTime!.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
          
              Row(
                children: [
                  const Text(
                    'Total Hours:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: screenWidth(context, 0.25),
                    child: TextFormField(
                      readOnly: true,
                      enabled: false,
                      controller: TextEditingController(
                        text: _totalHours != null
                            ? formatHoursToHM(_totalHours!)
                            : '',
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
          
              const SizedBox(height: 12),
          
              const SizedBox(height: 12),
          
              CustomButton(
                label: 'Submit Attendance',
                onPressed: _submitForm,
                widthFactor: 0.5,
                heightFactor: 0.1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
