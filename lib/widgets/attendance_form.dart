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

class AttendanceForm extends StatefulWidget {
  final void Function()? onSubmitSuccess;
  final Map<String, dynamic>? attendanceRecord; // For editing

  const AttendanceForm({
    super.key,
    this.onSubmitSuccess,
    this.attendanceRecord,
  });

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends State<AttendanceForm> {
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
    if (widget.attendanceRecord != null) {
      final record = widget.attendanceRecord!;
      _employeeIdController.text = record['employee_id']?.toString() ?? '';
      _workOrderIdController.text = record['work_order_id']?.toString() ?? '';
      _selectedDate = DateTime.parse(record['date']);
      _inTime = TimeUtils.parseTime(record['in_time']);
      _outTime = TimeUtils.parseTime(record['out_time']);

      _fetchEmployee();
      _fetchWorkOrder();
    }

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
        _dateError = 'Date cannot be in the future.';
      });
      return;
    } else {
      setState(() {
        _dateError = null;
      });
    }

    if (_totalHours == null || _totalHours! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total hours must be greater than 0.')),
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

    final employeeId = _employee!['id'];
    final formattedDate = _selectedDate.toIso8601String().split('T').first;

    // Check if selected date is a holiday
    final isHoliday = await supabase
        .from('holidays')
        .select()
        .eq('date', formattedDate)
        .maybeSingle();

    if (isHoliday != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('The selected date is a holiday. If work was performed, please submit an overtime request instead.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    //Check for existing attendance for this employee on this date when creating new record
    if (widget.attendanceRecord == null) {
      final existing = await supabase
          .from('attendance')
          .select()
          .eq('employee_id', employeeId)
          .eq('date', formattedDate)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Attendance already exists for this employee on this date.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    final data = {
      'employee_id': employeeId,
      'date': formattedDate,
      'work_order_id': _workOrder!['id'],
      'in_time':
          '${_inTime!.hour.toString().padLeft(2, '0')}:${_inTime!.minute.toString().padLeft(2, '0')}',
      'out_time':
          '${_outTime!.hour.toString().padLeft(2, '0')}:${_outTime!.minute.toString().padLeft(2, '0')}',
      'total_hours': _totalHours,
      'created_by': user.id,
    };

    if (widget.attendanceRecord != null) {
      final id = widget.attendanceRecord!['id'];
      await supabase.from('attendance').update(data).eq('id', id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance edited successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context);
    } else {
      await supabase.from('attendance').insert(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance submitted.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
    _resetForm();
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
                Center(
                  child: Text(
                    widget.attendanceRecord != null
                        ? "Edit Attendance"
                        : "Attendance Form",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
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
                  readOnly: widget.attendanceRecord != null,
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
                  label: _isLoading
                      ? 'Loading...'
                      : widget.attendanceRecord != null
                          ? 'Update Attendance'
                          : 'Add Attendance',
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
