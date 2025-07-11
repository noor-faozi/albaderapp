import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
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

  bool workOrderNotFound = false;
  bool projectNotFound = false;

  double? workOrderCost;
  List<Map<String, dynamic>> projectWorkOrders = [];
  double? projectTotalCost;

  final supabase = Supabase.instance.client;

  Future<double> fetchWorkOrderCost(String workOrderID) async {
    double total = 0.0;

    final attendanceData = await supabase
        .from('attendance')
        .select('amount')
        .eq('work_order_id', workOrderID);

    for (var row in attendanceData) {
      total += (row['amount'] ?? 0);
    }

    final overtimeData = await supabase
        .from('overtime')
        .select('amount')
        .eq('work_order_id', workOrderID)
        .eq('approved', true);

    for (var row in overtimeData) {
      total += (row['amount'] ?? 0);
    }

    return total;
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
      final cost = await fetchWorkOrderCost(woId);
      total += cost;
      results.add({'workOrderId': woId, 'cost': cost});
    }

    setState(() {
      projectWorkOrders = results;
      projectTotalCost = total;
    });
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
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
                    SearchInput(
                      controller: _workOrderController,
                      label: 'Enter Work Order ID',
                      onSearch: () async {
                        final cost = await fetchWorkOrderCost(
                            _workOrderController.text.trim());
                        setState(() {
                          if (cost == 0) {
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
                    if (workOrderCost != null)
                      Padding(
                        padding: EdgeInsets.only(top: padding),
                        child: Text(
                          'Labour Cost: AED ${workOrderCost!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
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
                              'AED ${wo['cost'].toStringAsFixed(2)}',
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
