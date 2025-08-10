import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_work_order_screen.dart';
import 'edit_work_order_screen.dart';

// Model
class WorkOrder {
  final String id;
  final String description;
  final String projectId;

  WorkOrder({
    required this.id,
    required this.description,
    required this.projectId,
  });

  factory WorkOrder.fromMap(Map<String, dynamic> map) {
    return WorkOrder(
      id: map['id'] as String,
      description: map['description'] as String,
      projectId: map['project_id'] as String,
    );
  }
}

class WorkOrdersScreen extends StatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  State<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends State<WorkOrdersScreen> {
  final supabase = Supabase.instance.client;

  String searchQuery = '';
  late Future<List<WorkOrder>> _workOrdersFuture;

  @override
  void initState() {
    super.initState();
    _workOrdersFuture = fetchWorkOrders();
  }

  Future<List<WorkOrder>> fetchWorkOrders() async {
    try {
      final data = await supabase.from('work_orders').select().order('id');
      return (data as List).map((e) => WorkOrder.fromMap(e)).toList();
    } catch (error) {
      throw Exception('Failed to load work orders: $error');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _workOrdersFuture = fetchWorkOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: 'Work Orders'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenPadding(context, 0.03)),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Work Order ID or Project ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim().toUpperCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<List<WorkOrder>>(
                future: _workOrdersFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error.toString()}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: firstColor));
                  }

                  List<WorkOrder> workOrders = snapshot.data!;
                  if (searchQuery.isNotEmpty) {
                    workOrders = workOrders
                        .where((wo) =>
                            wo.id.toUpperCase().contains(searchQuery) ||
                            wo.projectId.toUpperCase().contains(searchQuery))
                        .toList();
                  }

                  return WorkOrdersDataTableWidget(
                    workOrders: workOrders,
                    onRefresh: _refreshData,
                    onEdit: (wo) async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditWorkOrderScreen(workOrderRecord: {
                            'id': wo.id,
                            'description': wo.description,
                            'project_id': wo.projectId,
                          }),
                        ),
                      );
                      if (result == true) _refreshData();
                    },
                    onDelete: (wo) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                              'Are you sure you want to delete work order ${wo.id}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await supabase
                              .from('work_orders')
                              .delete()
                              .eq('id', wo.id);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Work order ${wo.id} deleted.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _refreshData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete work order: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWorkOrderScreen()),
          );
          if (result == true) _refreshData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Work Order'),
      ),
    );
  }
}

// DataTableSource
class WorkOrdersDataTable extends DataTableSource {
  final List<WorkOrder> workOrders;
  final void Function(WorkOrder) onEdit;
  final void Function(WorkOrder) onDelete;

  WorkOrdersDataTable({
    required this.workOrders,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= workOrders.length) return null;

    final wo = workOrders[index];
    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(
      color: WidgetStateProperty.all(rowColor),
      cells: [
        DataCell(Text(wo.id)),
        DataCell(Text(wo.projectId)),
        DataCell(Text(wo.description)),
        DataCell(Row(
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: gray500),
              onPressed: () => onEdit(wo),
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: gray500),
              onPressed: () => onDelete(wo),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => workOrders.length;

  @override
  int get selectedRowCount => 0;
}

// Widget to hold the PaginatedDataTable
class WorkOrdersDataTableWidget extends StatefulWidget {
  final List<WorkOrder> workOrders;
  final void Function(WorkOrder) onEdit;
  final void Function(WorkOrder) onDelete;
  final Future<void> Function() onRefresh;

  const WorkOrdersDataTableWidget(
      {super.key,
      required this.workOrders,
      required this.onEdit,
      required this.onDelete,
      required this.onRefresh});

  @override
  State<WorkOrdersDataTableWidget> createState() =>
      _WorkOrdersDataTableWidgetState();
}

class _WorkOrdersDataTableWidgetState extends State<WorkOrdersDataTableWidget> {
  late WorkOrdersDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = WorkOrdersDataTable(
      workOrders: widget.workOrders,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant WorkOrdersDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workOrders != widget.workOrders) {
      _data = WorkOrdersDataTable(
        workOrders: widget.workOrders,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenPadding(context, 0.03),
            vertical: screenPadding(context, 0.02),
          ),
          child: StyledDataTable(
            child: PaginatedDataTable(
              header: const Text('Work Orders'),
              rowsPerPage: 5,
              columns: const [
                DataColumn(label: Text('Work Order ID')),
                DataColumn(label: Text('Project ID')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Actions')),
              ],
              source: _data,
            ),
          ),
        ),
      ),
    );
  }
}
