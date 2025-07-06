import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/utils/time_utils.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/date_picker_form_field.dart';
import 'package:albaderapp/widgets/form_card_wrapper.dart';
import 'package:albaderapp/widgets/search_and_display_card.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';
import 'package:albaderapp/widgets/time_picker_form_field.dart';
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
  bool _isLoading = false;

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

  void _resetForm() {
    _formKey.currentState?.reset();

    _employeeIdController.clear();
    _workOrderIdController.clear();
    _inTimeController.clear();
    _outTimeController.clear();

    setState(() {
      _employee = null;
      _workOrder = null;
      _selectedDate = DateTime.now();
      _inTime = null;
      _outTime = null;
      _selectedWoId = null;
      _employeeNotFound = false;
      _workOrderNotFound = false;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

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
        SnackBar(
          content: const Text('Total hours must be greater than 0'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (_employee == null ||
        _inTime == null ||
        _outTime == null ||
        _workOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all fields'),
          backgroundColor: Colors.red.shade700,
        ),
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
        .from('overtime')
        .select()
        .eq('employee_id', employeeId)
        .eq('date', formattedDate)
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Attendance already submitted for this employee on this date',
          ),
          backgroundColor: Colors.red.shade700,
        ),
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
    setState(() {
      _isLoading = false;
    });
    _resetForm();
    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Overtime submitted successfully'),
        backgroundColor: Colors.green.shade700,
      ),
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
          child: FormCardWrapper(
            child: Column(
              children: [
                const Center(
                    child: Text(
                  "Overtime Form",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.7),
                )),
                SizedBox(height: screenHeight(context, 0.025)),
                DatePickerFormField(
                  selectedDate: _selectedDate,
                  onChanged: (newDate) {
                    setState(() => _selectedDate = newDate);
                  },
                  validator: (value) {
                    if (_selectedDate.isAfter(DateTime.now())) {
                      return 'Date cannot be in the future';
                    }
                    return null;
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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

                TimePickerFormField(
                  label: 'Clock In Time',
                  initialValue: _inTime,
                  onTimePicked: (picked) => setState(() => _inTime = picked),
                ),

                TimePickerFormField(
                  label: 'Clock Out Time:',
                  initialValue: _outTime,
                  onTimePicked: (picked) => setState(() => _outTime = picked),
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
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const SizedBox(height: 12),

                CustomButton(
                  label: _isLoading ? 'Loading...' : 'Add Overtime',
                  widthFactor: 0.8,
                  heightFactor: 0.1,
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (await showConfirmDialog(context,
                              'Are you sure you want to submit this record?')) {
                            _submitForm();
                          }
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
