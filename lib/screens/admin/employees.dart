import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Employees extends StatefulWidget {
  const Employees({super.key});

  @override
  State<Employees> createState() => _EmployeesState();
}

class _EmployeesState extends State<Employees> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> allEmployees = [];
  List<dynamic> filteredEmployees = [];
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    fetchAllEmployees();
  }

  Future<void> fetchAllEmployees() async {
    final response = await supabase.from('employee').select();

    print('Fetched employees: $response');

    setState(() {
      allEmployees = response;
      filteredEmployees = response;
    });
  }


  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query.trim();
    });

    if (query.isEmpty) {
      // Show all employees again
      setState(() {
        filteredEmployees = allEmployees;
      });
    } else {
      final id = int.tryParse(query);
      if (id != null) {
        final result = allEmployees.where((e) => e['id'] == id).toList();
        setState(() {
          filteredEmployees = result;
        });
      } else {
        setState(() {
          filteredEmployees = []; // invalid input
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Employees'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: onSearchChanged,
            ),
          ),
          Expanded(
             child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Profession')),
                ],
                rows: filteredEmployees.map((emp) {
                  return DataRow(cells: [
                    DataCell(Text(emp['id'].toString())),
                    DataCell(Text(emp['name'] ?? '')),
                    DataCell(Text(emp['profession'] ?? '')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
