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

  double? workOrderCost;
  List<Map<String, dynamic>> projectWorkOrders = [];
  double? projectTotalCost;

  final supabase = Supabase.instance.client;

Future<double> fetchWorkOrderCost(String workOrderID) async {
    double total = 0.0;

    // Attendance cost
    final attendanceData = await supabase
        .from('attendance')
        .select('amount')
        .eq('work_order_id', workOrderID);

    for (var row in attendanceData) {
      total += (row['amount'] ?? 0);
    }

    // Overtime cost
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Labour Cost Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Work Order Report",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _workOrderController,
              decoration: InputDecoration(
                labelText: 'Enter Work Order ID',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final cost = await fetchWorkOrderCost(
                        _workOrderController.text.trim());
                    setState(() {
                      workOrderCost = cost;
                    });
                  },
                ),
              ),
            ),
            if (workOrderCost != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Labour Cost: AED ${workOrderCost!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const Divider(height: 32),
            const Text("Project Report",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _projectController,
              decoration: InputDecoration(
                labelText: 'Enter Project ID',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    await fetchProjectCosts(_projectController.text.trim());
                  },
                ),
              ),
            ),
            if (projectWorkOrders.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Work Orders:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...projectWorkOrders.map((wo) => ListTile(
                    title: Text('Work Order: ${wo['workOrderId']}'),
                    trailing: Text('AED ${wo['cost'].toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  )),
              const Divider(),
              Text(
                'Total Labour Cost: AED ${projectTotalCost!.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
