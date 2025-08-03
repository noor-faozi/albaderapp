import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalaryReportScreen extends StatefulWidget {
  const SalaryReportScreen({super.key});

  @override
  State<SalaryReportScreen> createState() => _SalaryReportScreenState();
}

class _SalaryReportScreenState extends State<SalaryReportScreen> {
  int? employeeId;
  String employeeName = '';
  String profession = '';
  DateTime selectedMonth = DateTime.now();
  double totalAttendanceHours = 0;
  double totalAttendanceAmount = 0;
  double totalOvertimeHours = 0;
  double totalOvertimePay = 0;
  bool isLoading = true;
  bool isFutureMonth = false;

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    setState(() {
      isLoading = true;
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final supabase = Supabase.instance.client;

    final empRes = await supabase
        .from('employees')
        .select('id, name, profession')
        .eq('user_id', user.id)
        .maybeSingle();

    if (empRes == null || empRes['id'] == null) {
      setState(() => isLoading = false);
      return;
    }

    employeeId = empRes['id'];
    employeeName = empRes['name'] ?? '';
    profession = empRes['profession'] ?? '';

    final now = DateTime.now();
    isFutureMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    if (isFutureMonth) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      return;
    }

    final monthStart = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    final fromDate = DateFormat('yyyy-MM-dd').format(monthStart);
    final toDate = DateFormat('yyyy-MM-dd').format(monthEnd);

    final attendanceRes = await supabase
        .from('attendance')
        .select('total_hours, amount')
        .eq('employee_id', employeeId!)
        .gte('date', fromDate)
        .lte('date', toDate);

    double attendanceHours = 0;
    double attendanceAmount = 0;

    for (final row in attendanceRes) {
      attendanceHours += (row['total_hours'] ?? 0).toDouble();
      attendanceAmount += (row['amount'] ?? 0).toDouble();
    }

    final overtimeRes = await supabase
        .from('overtime')
        .select('total_hours, cost, amount')
        .eq('employee_id', employeeId!)
        .eq('approved', true)
        .gte('date', fromDate)
        .lte('date', toDate);

    double overtimeHours = 0;
    double overtimeAmount = 0;

    for (final row in overtimeRes) {
      final hours = (row['total_hours'] ?? 0).toDouble();
      final cost = (row['cost'] ?? 0).toDouble();
      final amount =
          row['amount'] != null ? row['amount'].toDouble() : hours * cost;
      overtimeHours += hours;
      overtimeAmount += amount;
    }

    setState(() {
      totalAttendanceHours = attendanceHours;
      totalAttendanceAmount = attendanceAmount;
      totalOvertimeHours = overtimeHours;
      totalOvertimePay = overtimeAmount;
      isLoading = false;
    });
  }

  Future<void> selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Month',
      fieldLabelText: 'Month',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
      await fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = DateFormat('MMMM yyyy').format(selectedMonth);
    final rangeStr =
        '1 ${DateFormat('MMMM').format(selectedMonth)} - ${DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month)} ${DateFormat('MMMM').format(selectedMonth)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 53, 100, 159),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Salary Report',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    onPressed: () => selectMonth(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isFutureMonth
                          ? const Center(
                              child: Text(
                                'Salary not released this month.',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w500),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildEmployeeCard(),
                                  const SizedBox(height: 24),
                                  _buildMonthHeader(monthStr, rangeStr),
                                  const SizedBox(height: 24),
                                  _buildSalaryCard(),
                                ],
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'Employee Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employeeName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Employee ID: $employeeId'),
                Text('Profession: $profession'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(String monthStr, String rangeStr) {
    return Column(
      children: [
        Text(
          'Salary Details',
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '$monthStr ($rangeStr)',
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSalaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ReportRow(
              label: 'Attendance Hours',
              value: '${totalAttendanceHours.toStringAsFixed(2)} hrs',
            ),
            ReportRow(
              label: 'Attendance Pay',
              value: 'RM ${totalAttendanceAmount.toStringAsFixed(2)}',
            ),
            const Divider(height: 28),
            ReportRow(
              label: 'Overtime Hours',
              value: '${totalOvertimeHours.toStringAsFixed(2)} hrs',
            ),
            ReportRow(
              label: 'Overtime Pay',
              value: 'RM ${totalOvertimePay.toStringAsFixed(2)}',
            ),
            const Divider(height: 28),
            ReportRow(
              label: 'Total Pay',
              value:
                  'RM ${(totalAttendanceAmount + totalOvertimePay).toStringAsFixed(2)}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const ReportRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
