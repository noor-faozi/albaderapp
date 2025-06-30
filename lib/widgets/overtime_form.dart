import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/utils/time_utils.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/search_and_display_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OvertimeForm extends StatefulWidget {
  final void Function()? onSubmitSuccess;

  const OvertimeForm({
    super.key,
    this.onSubmitSuccess,
  });

  @override
  State<OvertimeForm> createState() => _OvertimeFormState();
}

class _OvertimeFormState extends State<OvertimeForm> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final _employeeIdController = TextEditingController();
  final _workOrderIdController = TextEditingController();
  final _inTimeController = TextEditingController();
  final _outTimeController = TextEditingController();

  Map<String, dynamic>? _employee;
  Map<String, dynamic>? _workOrder;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  String? _selectedWoId;
  String? _dateError;
  bool _employeeNotFound = false;
  bool _workOrderNotFound = false;

  double? get _totalHours => TimeUtils.calculateTotalHours(_inTime, _outTime);

  Future<void> _fetchEmployee() async {
    final id = _employeeIdController.text.trim();
    final result =
        await supabase.from('employees').select().eq('id', id).maybeSingle();
    setState(() {
      _employee = result;
      _employeeNotFound = result == null;
    });
  }

  Future<void> _fetchWorkOrder() async {
    final id = _workOrderIdController.text.trim();
    final result =
        await supabase.from('work_orders').select().eq('id', id).maybeSingle();
    setState(() {
      _workOrder = result;
      _workOrderNotFound = result == null;
    });
  }

  @override
  void initState() {
    super.initState();
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

    if (_totalHours == null || _totalHours! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total hours must be greater than 0')),
      );
      return;
    }

    if (_employee == null ||
        _inTime == null ||
        _outTime == null ||
        _workOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final employeeId = _employee!['id'];
    final formattedDate = _selectedDate.toIso8601String().split('T').first;

    //Check for existing overtime attendance for this employee on this date
    final existing = await supabase
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .eq('date', formattedDate)
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Attendance already submitted for this employee on this date')),
      );
      return;
    }

    // Check if the date is a holiday
    final holidayResult = await supabase
        .from('holidays')
        .select('id')
        .eq('date', _selectedDate.toIso8601String())
        .maybeSingle();

    final holidayId = holidayResult?['id']; // Can be null

    // Note: cost and amount are calculated via DB trigger
    final data = {
      'employee_id': _employee!['id'],
      'date': _selectedDate.toIso8601String(),
      'in_time':
          '${_inTime!.hour.toString().padLeft(2, '0')}:${_inTime!.minute.toString().padLeft(2, '0')}',
      'out_time':
          '${_outTime!.hour.toString().padLeft(2, '0')}:${_outTime!.minute.toString().padLeft(2, '0')}',
      'total_hours': _totalHours,
      'work_order_id': _workOrder?['id'],
      'holiday_id': holidayId,
      'created_by': user.id,
    };

    await supabase.from('overtime').insert(data);

    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Overtime submitted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verticalPadding = screenPadding(context, 0.015); // For field height
    final buttonHeight = screenPadding(context, 0.08); // For button height

    return Padding(
      padding: EdgeInsets.all(screenPadding(context, 0.01)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Card(
            elevation: 10,
            child: Padding(
              padding: EdgeInsets.all(screenPadding(context, 0.06)),
              child: Column(
                children: [
                  const Center(child: Text("Overtime Form", style: TextStyle(fontSize: 18),)),
                  SizedBox(height: screenHeight(context, 0.025)),
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
              
                  // Employee:
                  SearchAndDisplayCard<Map<String, dynamic>>(
                    controller: _employeeIdController,
                    exactDigits: 3,
                    label: 'Employee Code',
                    onSearch: _fetchEmployee,
                    data: _employee,
                    notFound: _employeeNotFound,
                    verticalPadding: verticalPadding,
                    horizontalPadding: screenPadding(context, 0.04),
                    buttonHeight: buttonHeight,
                    detailsBuilder: (employee) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Employee Details",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text("Employee Code: ${employee['id']}"),
                        Text("Name: ${employee['name']}"),
                        Text("Profession: ${employee['profession']}"),
                      ],
                    ),
                  ),
              
                  SizedBox(height: screenHeight(context, 0.025)),
              
                  // Work Order:
                  SearchAndDisplayCard<Map<String, dynamic>>(
                    controller: _workOrderIdController,
                    label: 'Work Order Code',
                    exactDigits: 10,
                    onSearch: _fetchWorkOrder,
                    data: _workOrder,
                    notFound: _workOrderNotFound,
                    verticalPadding: verticalPadding,
                    horizontalPadding: screenPadding(context, 0.04),
                    buttonHeight: buttonHeight,
                    detailsBuilder: (workOrder) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Work Order Details",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text("Work Order Code: ${workOrder['id']}"),
                        Text("Description: ${workOrder['description']}"),
                      ],
                    ),
                  ),
              
                  SizedBox(height: screenHeight(context, 0.025)),
              
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
                          _inTime == null
                              ? 'Select Time'
                              : _inTime!.format(context),
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
                                ? TimeUtils.formatHoursToHM(_totalHours!)
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
                    label: 'Submit Overtime',
                    onPressed: _submitForm,
                    widthFactor: 0.5,
                    heightFactor: 0.1,
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
