import 'package:albaderapp/screens/add_holiday_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:albaderapp/widgets/styled_date_table.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysState();
}

class _HolidaysState extends State<HolidaysScreen> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final Stream<List<Map<String, dynamic>>> holidaysStream = supabase
        .from('holidays')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true)
        .map((event) {
          final today = DateTime.now();
          return (event as List).cast<Map<String, dynamic>>().where((holiday) {
            final holidayDate = DateTime.parse(holiday['date']);
            return !holidayDate.isBefore(
              DateTime(today.year, today.month, today.day),
            );
          }).toList();
        });

    return Scaffold(
      appBar: CustomAppBar(title: 'Holidays'),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: holidaysStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: firstColor,
                  ));
                }

                List<Map<String, dynamic>> holidays = snapshot.data!;

                if (holidays.isEmpty) {
                  return const Center(
                    child: Text(
                      'No upcoming holidays.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return HolidaysDataTableWidget(
                  holidays: holidays,
                  onEdit: (holiday) {
                    // navigate to edit screen
                  },
                  onDelete: (holiday) {
                    // show delete confirmation
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddHolidayScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Holiday'),
      ),
    );
  }
}

// DataTableSource implementation for paginated data table
class HolidaysDataTable extends DataTableSource {
  final List<Map<String, dynamic>> holidays;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  HolidaysDataTable({
    required this.holidays,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= holidays.length) return null;

    final holiday = holidays[index];
    final rowColor = index % 2 == 0 ? Colors.white : Colors.grey[100];
    return DataRow(color: WidgetStateProperty.all(rowColor), cells: [
      DataCell(Text(holiday['title'] ?? '')),
      DataCell(Text(holiday['date'] ?? '')),
      DataCell(Row(
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: gray500),
            onPressed: () => onEdit(holiday),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: gray500),
            onPressed: () => onDelete(holiday),
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => holidays.length;

  @override
  int get selectedRowCount => 0;
}

class HolidaysDataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> holidays;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const HolidaysDataTableWidget({
    super.key,
    required this.holidays,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<HolidaysDataTableWidget> createState() =>
      _EmployeesDataTableWidgetState();
}

class _EmployeesDataTableWidgetState extends State<HolidaysDataTableWidget> {
  late HolidaysDataTable _data;

  @override
  void initState() {
    super.initState();
    _data = HolidaysDataTable(
      holidays: widget.holidays,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  void didUpdateWidget(covariant HolidaysDataTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holidays != widget.holidays) {
      _data = HolidaysDataTable(
        holidays: widget.holidays,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth(context, 0.04),
          vertical: screenHeight(context, 0.02),
        ),
        child: StyledDataTable(
          child: PaginatedDataTable(
            header: const Text('Holidays'),
            rowsPerPage: 7,
            columns: const [
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Action')), // Added column
            ],
            source: _data,
          ),
        ),
      ),
    );
  }
}
