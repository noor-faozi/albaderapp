import 'package:albaderapp/screens/admin/project_excel_export.dart';
import 'package:albaderapp/screens/admin/work_order_excel_export.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/search_input.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _workOrderController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;

  bool workOrderNotFound = false;
  bool projectNotFound = false;

  double? workOrderCost;
  List<Map<String, dynamic>> projectWorkOrders = [];
  double? projectTotalCost;

  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchWorkOrderDetails(
    String workOrderID, DateTime fromDate, DateTime toDate) async {
      final workOrderExists = await supabase
          .from('work_orders')
          .select('id')
          .eq('id', workOrderID)
          .maybeSingle();

      if (workOrderExists == null) return {};

      // Attendance records
      var attendanceQuery = supabase
          .from('attendance')
          .select('employee_id, total_hours, amount, date')
          .eq('work_order_id', workOrderID);

      // Overtime records
      var overtimeQuery = supabase
          .from('overtime')
          .select('employee_id, total_hours, amount, date')
          .eq('work_order_id', workOrderID)
          .eq('approved', true);

      attendanceQuery = attendanceQuery.gte('date', fromDate.toIso8601String());
      overtimeQuery = overtimeQuery.gte('date', fromDate.toIso8601String());
      attendanceQuery = attendanceQuery.lte('date', toDate.toIso8601String());
      overtimeQuery = overtimeQuery.lte('date', toDate.toIso8601String());
    
      final attendanceData = await attendanceQuery;
      final overtimeData = await overtimeQuery;

      Map<String, Map<String, dynamic>> employeeSummary = {};
      double totalCost = 0.0;
      double totalHours = 0.0;

      // Process attendance
      for (var row in attendanceData) {
        final empId = row['employee_id'].toString();
        final hours = (row['total_hours'] ?? 0).toDouble();
        final amount = (row['amount'] ?? 0).toDouble();

        if (!employeeSummary.containsKey(empId)) {
          employeeSummary[empId] = {
            'hours': 0.0,
            'cost': 0.0,
          };
        }
        employeeSummary[empId]!['hours'] += hours;
        employeeSummary[empId]!['cost'] += amount;

        totalHours += hours;
        totalCost += amount;
      }

      // Process overtime
      for (var row in overtimeData) {
        final empId = row['employee_id'].toString();
        final hours = (row['total_hours'] ?? 0).toDouble();
        final amount = (row['amount'] ?? 0).toDouble();

        if (!employeeSummary.containsKey(empId)) {
          employeeSummary[empId] = {
            'hours': 0.0,
            'cost': 0.0,
          };
        }
        employeeSummary[empId]!['hours'] += hours;
        employeeSummary[empId]!['cost'] += amount;

        totalHours += hours;
        totalCost += amount;
      }

      return {
        'workOrderId': workOrderID,
        'employees': employeeSummary,
        'totalHours': totalHours,
        'totalCost': totalCost,
      };
    }

  Future<void> fetchProjectCosts(String projectID) async {
    final workOrders = await supabase
        .from('work_orders')
        .select('id')
        .eq('project_id', projectID);

    List<Map<String, dynamic>> results = [];
    double total = 0.0;

    for (var row in workOrders) {
      final woId = row['id'];
      final details = await fetchWorkOrderDetails(
          woId, _fromDate ?? DateTime(2000), _toDate ?? DateTime(2100));
      if (details.isNotEmpty) {
        results.add(details);
        total += details['totalCost'];
      }
    }

    setState(() {
      projectWorkOrders = results;
      projectTotalCost = total;
    });
  }

  Future<double?> fetchWorkOrderCost(String workOrderID) async {
    final workOrderExists = await supabase
        .from('work_orders')
        .select('id')
        .eq('id', workOrderID)
        .maybeSingle();

    if (workOrderExists == null) {
      // Work order doesn't exist
      return null;
    }

    double total = 0.0;

    var attendanceQuery = supabase
        .from('attendance')
        .select('amount')
        .eq('work_order_id', workOrderID);

    var overtimeQuery = supabase
        .from('overtime')
        .select('amount')
        .eq('work_order_id', workOrderID)
        .eq('approved', true);

    if (_fromDate != null) {
      attendanceQuery =
          attendanceQuery.gte('date', _fromDate!.toIso8601String());
      overtimeQuery = overtimeQuery.gte('date', _fromDate!.toIso8601String());
    }
    if (_toDate != null) {
      attendanceQuery = attendanceQuery.lte('date', _toDate!.toIso8601String());
      overtimeQuery = overtimeQuery.lte('date', _toDate!.toIso8601String());
    }

    final attendanceData = await attendanceQuery;
    final overtimeData = await overtimeQuery;

    for (var row in attendanceData) {
      total += (row['amount'] ?? 0);
    }
    for (var row in overtimeData) {
      total += (row['amount'] ?? 0);
    }

    return total;
  }


  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, bool isFrom) async {
    final initialDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = screenPadding(context, 0.04);

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: padding * 1.5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Use this report to calculate labour costs for a specific Work Order or across an entire Project.\n"
                      "The total is based on attendance and approved overtime records.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // WORK ORDER SECTION
Card(
  elevation: 3,
  margin: const EdgeInsets.only(bottom: 24),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(padding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Work Order Report",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline,
                size: 18, color: Colors.blueGrey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Enter a Work Order ID to view the labour cost linked with it.\n"
                "This includes attendance and approved overtime entries.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: padding),
        // Date inputs
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, _fromDateController, true),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _fromDateController,
                    decoration: InputDecoration(
                      labelText: 'From Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, _toDateController, false),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _toDateController,
                    decoration: InputDecoration(
                      labelText: 'To Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: padding),

        SearchInput(
          controller: _workOrderController,
          label: 'Enter Work Order ID',
          onSearch: () async {
            final cost = await fetchWorkOrderCost(
              _workOrderController.text.trim(),
            );
            setState(() {
              if (cost == null) {
                workOrderNotFound = true;
                workOrderCost = null;
              } else {
                workOrderCost = cost;
                workOrderNotFound = false;
              }
            });
          },
        ),
        if (workOrderNotFound)
          Padding(
            padding: EdgeInsets.only(top: padding),
            child: const Text(
              'Work Order not found',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        if (workOrderCost == 0 && !workOrderNotFound)
          Padding(
            padding: EdgeInsets.only(top: padding),
            child: const Text(
              'No labour cost found in selected date range.',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
        if (workOrderCost != null && workOrderCost != 0) ...[
          Padding(
            padding: EdgeInsets.only(top: padding),
            child: Text(
              'Labour Cost: AED ${workOrderCost!.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () async {
              try {
                final details = await fetchWorkOrderDetails(
                  _workOrderController.text.trim(),
                  _fromDate!,
                  _toDate!,
                );
                if (details.isNotEmpty) {
                  await exportWorkOrderToExcel(
                    details,
                    _fromDate!,
                    _toDate!,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Work Order Excel exported successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No data to export for this Work Order')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.download, size: 20),
            label: const Text(
              'Export to Excel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              elevation: 3,
            ),
          ),
        ],
      ],
    ),
  ),
),

            // PROJECT SECTION
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Project Report",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Enter a Project ID to fetch all related work orders and their individual labour costs.\n"
                            "This helps estimate the total manpower cost for the entire project.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: padding),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _selectDate(context, _fromDateController, true),
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _fromDateController,
                                decoration: InputDecoration(
                                  labelText: 'From Date',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _selectDate(context, _toDateController, false),
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _toDateController,
                                decoration: InputDecoration(
                                  labelText: 'To Date',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: padding),

                    SearchInput(
                      controller: _projectController,
                      label: 'Enter Project ID',
                      onSearch: () async {
                        await fetchProjectCosts(_projectController.text.trim());
                        setState(() {
                          if (projectWorkOrders.isEmpty) {
                            projectNotFound = true;
                            projectTotalCost = null;
                          } else {
                            projectNotFound = false;
                          }
                        });
                      },
                    ),
                    if (projectNotFound)
                      Padding(
                        padding: EdgeInsets.only(top: padding),
                        child: const Text(
                          'Project not found',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (projectTotalCost == 0 && !projectNotFound)
                      Padding(
                        padding: EdgeInsets.only(top: padding),
                        child: const Text(
                          'No labour cost found for this project in selected date range.',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (projectWorkOrders.isNotEmpty) ...[
                      SizedBox(height: padding),
                      const Text('Work Orders:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...projectWorkOrders.map((wo) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('Work Order: ${wo['workOrderId']}'),
                            trailing: Text(
                              'AED ${(wo['totalCost'] ?? 0.0).toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),

                          )),
                      const Divider(),
                      Text(
                        'Total Labour Cost: AED ${projectTotalCost!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),

                      const SizedBox(height: 12),

                       ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await exportProjectReportToExcel(
                              projectId: _projectController.text.trim(),
                              fromDate: _fromDate!,
                              toDate: _toDate!,
                              workOrders: projectWorkOrders,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Excel exported successfully')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Export failed: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text(
                          'Export to Excel',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 3,
                        ),
                      ),
                    ],
                                    ],
                  
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
