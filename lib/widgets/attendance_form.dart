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
import 'package:uuid/uuid.dart';

class AttendanceForm extends StatefulWidget {
  final void Function()? onSubmitSuccess;
  final Map<String, dynamic>? attendanceRecord;

  const AttendanceForm(
      {super.key, this.onSubmitSuccess, this.attendanceRecord});

  @override
  State<AttendanceForm> createState() => _AttendanceFormState();
}

class WorkOrderEntry {
  final TextEditingController idController = TextEditingController();
  Map<String, dynamic>? workOrder;
  double? hours;
  bool notFound = false;
}

class _AttendanceFormState extends State<AttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final _employeeIdController = TextEditingController();
  final _inTimeController = TextEditingController();
  final _outTimeController = TextEditingController();

  bool _isLoading = false;

  Map<String, dynamic>? _employee;
  bool _employeeNotFound = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _inTime;
  TimeOfDay? _outTime;
  String? _dateError;

  List<WorkOrderEntry> _workOrders = [WorkOrderEntry()];

  String? _groupId; // store group_id for editing or new

  double? get _totalHours => TimeUtils.calculateTotalHours(_inTime, _outTime);

  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    if (widget.attendanceRecord != null) {
      final record = widget.attendanceRecord!;
      _groupId = record['group_id'] as String?;

      _employeeIdController.text = record['employee_id']?.toString() ?? '';
      _selectedDate = DateTime.tryParse(record['date'] ?? '') ?? DateTime.now();

      // Parse in_time and out_time strings to TimeOfDay
      final inTimeStr = record['in_time'] as String?;
      final outTimeStr = record['out_time'] as String?;
      if (inTimeStr != null) _inTime = _parseTimeOfDay(inTimeStr);
      if (outTimeStr != null) _outTime = _parseTimeOfDay(outTimeStr);

      _employee = {
        'id': record['employee_id'],
        'name': record['employee_name'] ?? '',
        'profession': record['employee_profession'] ?? '',
      };

      _workOrders = [];

      // Case 1: record contains a list of work orders (combined record)

      if (_groupId != null) {
        // Fetch all attendance rows with this group_id
        final response = await supabase
            .from('attendance')
            .select('work_order_id, total_hours')
            .eq('group_id', _groupId as Object);

        for (final attRow in response) {
          final entry = WorkOrderEntry();
          entry.idController.text = attRow['work_order_id']?.toString() ?? '';
          entry.hours = (attRow['total_hours'] is num)
              ? (attRow['total_hours'] as num).toDouble()
              : null;
          _workOrders.add(entry);
          await _fetchWorkOrder(entry);
        }
      }

      // Case 2: record only has one work_order_id and no list (single row)
      else if (record['work_order_id'] != null) {
        final entry = WorkOrderEntry();
        entry.idController.text = record['work_order_id'].toString();
        entry.workOrder = {
          'id': record['work_order_id'],
          'description': record['work_order_description'] ?? '',
        };
        entry.hours = (record['total_hours'] is num)
            ? (record['total_hours'] as num).toDouble()
            : null;
        entry.notFound = entry.workOrder == null;
        _workOrders.add(entry);
        _fetchWorkOrder(entry);
      }

      // If no work orders at all, initialize with one empty entry
      else {
        _workOrders.add(WorkOrderEntry());
      }
      _fetchEmployee();
    }
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    // expects 'HH:mm'
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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

  Future<void> _fetchWorkOrder(WorkOrderEntry entry) async {
    final id = entry.idController.text.trim();
    final result =
        await supabase.from('work_orders').select().eq('id', id).maybeSingle();
    if (mounted) {
      setState(() {
        entry.workOrder = result;
        entry.notFound = result == null;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _employeeIdController.clear();
    _inTimeController.clear();
    _outTimeController.clear();
    setState(() {
      _employee = null;
      _selectedDate = DateTime.now();
      _inTime = null;
      _outTime = null;
      _employeeNotFound = false;
      _workOrders = [WorkOrderEntry()];
      _groupId = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDateOnly =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDateOnly.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Date cannot be in the future.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (_totalHours == null || _totalHours! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total hours must be greater than 0.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (_workOrders.length > 1) {
      final sumOfWoh =
          _workOrders.fold<double>(0.0, (sum, wo) => sum + (wo.hours ?? 0));
      if ((sumOfWoh - _totalHours!).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Work order hours must sum to total hours.')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

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
      setState(() => _isLoading = false);
      return;
    }

    final absence = await supabase
        .from('absence_view') 
        .select('id, is_absent, is_sickleave')
        .eq('employee_id', _employee!['id'])
        .eq('date', formattedDate)
        .or('is_absent.eq.true,is_sickleave.eq.true')
        .maybeSingle();

    if (absence != null) {
      String message =
          'This employee already has an absence recorded for this date.';
      if (absence['is_sickleave'] == true) {
        message = 'Sick leave already recorded for this employee on this date.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final isEditing = widget.attendanceRecord != null;
    final workOrderIds = _workOrders
        .map((wo) => wo.workOrder?['id'].toString())
        .whereType<String>()
        .toSet();

    String? groupId = _groupId;
    if (_workOrders.length > 1) {
      groupId ??= _uuid.v4();
    } else {
      final wo = _workOrders.first;
      wo.hours = _totalHours;
      groupId = null;
    }

    try {
      final existingRecords = await supabase
          .from('attendance')
          .select()
          .eq('employee_id', _employee!['id'])
          .eq('date', formattedDate);

      final existingMap = <String, Map<String, dynamic>>{};
      for (final record in existingRecords) {
        final woId = record['work_order_id']?.toString();
        if (woId != null) existingMap[woId] = record;
      }

      final existingWorkOrderIds = existingMap.keys.toSet();
      final removedIds = existingWorkOrderIds.difference(workOrderIds);
      final newIds = workOrderIds.difference(existingWorkOrderIds);
      final sharedIds = workOrderIds.intersection(existingWorkOrderIds);

      // Update shared
      for (final wo in _workOrders) {
        final woId = wo.workOrder?['id']?.toString();
        if (woId == null || wo.hours == null) continue;

        if (sharedIds.contains(woId)) {
          final record = existingMap[woId]!;
          final changed = record['total_hours'] != wo.hours ||
              record['in_time'] != _formatTime(_inTime!) ||
              record['out_time'] != _formatTime(_outTime!) ||
              record['group_id'] != groupId;

          if (changed) {
            await supabase.from('attendance').update({
              'employee_id': _employee!['id'],
              'date': formattedDate,
              'in_time': _formatTime(_inTime!),
              'out_time': _formatTime(_outTime!),
              'total_hours': wo.hours,
              'created_by': user.id,
              'group_id': groupId,
            }).eq('id', record['id']);
          }
        }
      }

      // Insert new
      for (final wo in _workOrders) {
        final woId = wo.workOrder?['id']?.toString();
        if (woId == null || wo.hours == null) continue;
        if (newIds.contains(woId)) {
          await supabase.from('attendance').insert({
            'employee_id': _employee!['id'],
            'date': formattedDate,
            'in_time': _formatTime(_inTime!),
            'out_time': _formatTime(_outTime!),
            'total_hours': wo.hours,
            'work_order_id': wo.workOrder?['id'],
            'created_by': user.id,
            'group_id': groupId,
          });
        }
      }

      // Delete removed
      for (final id in removedIds) {
        final recordId = existingMap[id]!['id'];
        await supabase.from('attendance').delete().eq('id', recordId);
      }

      // Ungroup if only one record remains
      if (groupId != null) {
        final stillGrouped = await supabase
            .from('attendance')
            .select()
            .eq('employee_id', _employee!['id'])
            .eq('date', formattedDate)
            .eq('group_id', groupId);

        if (stillGrouped.length == 1) {
          await supabase
              .from('attendance')
              .update({'group_id': null}).eq('id', stillGrouped.first['id']);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance submitted.'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      if (isEditing) {
        Navigator.pop(context);
      } else {
        _resetForm();
      }

      if (widget.onSubmitSuccess != null) widget.onSubmitSuccess!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save attendance: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
                Center(
                  child: Text("Attendance Form",
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.7)),
                ),
                const SizedBox(height: 16),
                DatePickerFormField(
                  selectedDate: _selectedDate,
                  onChanged: (newDate) =>
                      setState(() => _selectedDate = newDate),
                ),
                const SizedBox(height: 16),
                SearchAndDisplayCard<Map<String, dynamic>>(
                  controller: _employeeIdController,
                  label: 'Employee Code',
                  exactDigits: 3,
                  onSearch: _fetchEmployee,
                  data: _employee,
                  notFound: _employeeNotFound,
                  verticalPadding: verticalPadding,
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
                const SizedBox(height: 16),
                TimePickerFormField(
                  label: 'Clock In Time',
                  initialValue: _inTime,
                  onTimePicked: (picked) => setState(() => _inTime = picked),
                ),
                TimePickerFormField(
                  label: 'Clock Out Time',
                  initialValue: _outTime,
                  onTimePicked: (picked) => setState(() => _outTime = picked),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < _workOrders.length; i++) ...[
                  const Divider(),
                  SearchAndDisplayCard<Map<String, dynamic>>(
                    controller: _workOrders[i].idController,
                    label: 'Work Order Code',
                    exactDigits: 10,
                    onSearch: () => _fetchWorkOrder(_workOrders[i]),
                    data: _workOrders[i].workOrder,
                    notFound: _workOrders[i].notFound,
                    verticalPadding: verticalPadding,
                    horizontalPadding: screenPadding(context, 0.04),
                    buttonHeight: buttonHeight,
                    detailsBuilder: (wo) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Code: ${wo['id']}"),
                        Text("Description: ${wo['description']}"),
                      ],
                    ),
                  ),
                  if (_workOrders.length > 1)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Hours',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          initialValue: _workOrders[i].hours?.toString(),
                          validator: (value) {
                            final parsed = double.tryParse(value ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Enter valid hours';
                            }
                            return null;
                          },
                          onChanged: (val) =>
                              _workOrders[i].hours = double.tryParse(val),
                        ),
                      ),
                    ),
                  if (_workOrders.length == 1) const SizedBox.shrink(),
                  if (_workOrders.length > 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _workOrders.removeAt(i)),
                        child: const Text('Remove'),
                      ),
                    ),
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () =>
                      setState(() => _workOrders.add(WorkOrderEntry())),
                  child: const Text('Add Work Order'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Total Hours:'),
                    const Spacer(),
                    Text(_totalHours != null
                        ? TimeUtils.formatHoursToHM(_totalHours!)
                        : '-')
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: _isLoading ? 'Saving...' : 'Submit Attendance',
                  widthFactor: 0.8,
                  heightFactor: 0.1,
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (await showConfirmDialog(
                              context, 'Submit all work order entries?')) {
                            await _submitForm();
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
