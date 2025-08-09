import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/utils/time_utils.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/date_picker_form_field.dart';
import 'package:albaderapp/widgets/form_card_wrapper.dart';
import 'package:albaderapp/widgets/search_and_display_card.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AbsenceType { absent, sickLeave }

class AbsenceForm extends StatefulWidget {
  final VoidCallback? onSubmitSuccess;
  final Map<String, dynamic>? absenceRecord;
  const AbsenceForm({Key? key, this.onSubmitSuccess, this.absenceRecord})
      : super(key: key);

  @override
  State<AbsenceForm> createState() => _AbsenceFormState();
}

class _AbsenceFormState extends State<AbsenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  AbsenceType _absenceType = AbsenceType.absent;
  bool _isLoading = false;

  bool _isSubmitting = false;
  Map<String, dynamic>? _employee;
  bool _employeeNotFound = false;
  final supabase = Supabase.instance.client;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    if (widget.absenceRecord != null) {
      final record = widget.absenceRecord!;
      _employeeIdController.text = record['employee_id'].toString();
      _selectedDate = DateTime.parse(record['date']);
      _absenceType = record['is_sickleave'] == true
          ? AbsenceType.sickLeave
          : AbsenceType.absent;
      _fetchEmployee();
    }
  }

  double? get _totalHours {
    if (_absenceType == AbsenceType.sickLeave) {
      return 8.0; // Full day salary hours
    } else if (_absenceType == AbsenceType.absent) {
      return 0.0; // No hours if absent
    }
  }
Future<void> _submitAbsence() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDateOnly.isAfter(today)) {
      setState(() {
        _dateError = 'Date cannot be in the future.';
        _isSubmitting = false;
      });
      return;
    } else {
      _dateError = null;
    }

    // Check for holiday
    final formattedDate = _selectedDate.toIso8601String().split('T').first;
    final isHoliday = await supabase
        .from('holidays')
        .select()
        .eq('date', formattedDate)
        .maybeSingle();

    if (isHoliday != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Date is a holiday. Submit overtime instead.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final userId = supabase.auth.currentUser?.id;
    final employeeId = int.parse(_employeeIdController.text.trim());
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Check for existing attendance or absence, excluding current record if updating
    final excludeId = widget.absenceRecord != null
        ? widget.absenceRecord!['id'].toString()
        : null;

    var query = supabase
        .from('attendance')
        .select('id')
        .eq('employee_id', employeeId)
        .eq('date', selectedDateStr);

    // Exclude current record by ID if updating
    if (excludeId != null) {
      query = query.not('id', 'eq', excludeId);
    }

    final existingConflict = await query.maybeSingle();

    if (existingConflict != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Attendance already recorded for this employee on this date.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final attendanceData = {
      'employee_id': employeeId,
      'date': selectedDateStr,
      'in_time': null,
      'out_time': null,
      'total_hours': _totalHours,
      'is_absent': true,
      'is_sickleave': _absenceType == AbsenceType.sickLeave,
      'work_order_id': null,
      'created_by': userId,
    };

    try {
      if (widget.absenceRecord != null) {
        // UPDATE existing record
        await supabase
            .from('attendance')
            .update(attendanceData)
            .eq('id', widget.absenceRecord!['id']);
      } else {
        // INSERT new record
        await supabase.from('attendance').insert(attendanceData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.absenceRecord != null
                ? 'Absence updated successfully'
                : 'Absence recorded successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        widget.onSubmitSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save absence: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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

  @override
  void dispose() {
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verticalPadding = screenPadding(context, 0.015);
    final buttonHeight = screenPadding(context, 0.08);
    return Padding(
      padding: EdgeInsets.all(screenPadding(context, 0.01)),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: FormCardWrapper(
            child: Column(
              children: [
                const Center(
                  child: Text("Record Absence",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.7)),
                ),
                const SizedBox(height: 16),
                DatePickerFormField(
                  selectedDate: _selectedDate,
                  onChanged: widget.absenceRecord == null
                      ? (newDate) => setState(() => _selectedDate = newDate)
                      : (newDate) {}, // empty function instead of null
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                SearchAndDisplayCard<Map<String, dynamic>>(
                  controller: _employeeIdController,
                  label: 'Employee Code',
                  exactDigits: 3,
                  onSearch: _fetchEmployee,
                  data: _employee,
                  notFound: _employeeNotFound,
                  verticalPadding: verticalPadding,
                  enabled: widget.absenceRecord == null,
                  horizontalPadding: screenPadding(context, 0.04),
                  buttonHeight: buttonHeight,
                  detailsBuilder: (employee) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Employee Code: ${employee['id']}"),
                      Text("Name: ${employee['name']}"),
                      Text("Profession: ${employee['profession']}"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<AbsenceType>(
                  value: _absenceType,
                  onChanged: (val) {
                    if (val != null) setState(() => _absenceType = val);
                  },
                  decoration: InputDecoration(
                    labelText: 'Absence Type',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: firstColorLight, width: 2),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AbsenceType.absent,
                      child: Text('Absent (Unpaid)'),
                    ),
                    DropdownMenuItem(
                      value: AbsenceType.sickLeave,
                      child: Text('Sick Leave (Paid)'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Total Hours:'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100], // optional background color
                      ),
                      child: Text(
                        _totalHours != null
                            ? TimeUtils.formatHoursToHM(_totalHours!)
                            : '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: _isLoading
                      ? 'Saving...'
                      : widget.absenceRecord != null
                          ? 'Update Absence'
                          : 'Submit Absence',
                  widthFactor: 0.8,
                  heightFactor: 0.1,
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (await showConfirmDialog(
                              context, 'Submit This absence record?')) {
                            await _submitAbsence();
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
