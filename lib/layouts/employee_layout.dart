import 'package:albaderapp/auth/auth_service.dart';
import 'package:albaderapp/screens/employee/salary_report_screen.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'common_drawer.dart';

class EmployeeLayout extends StatefulWidget {
  const EmployeeLayout({super.key});

  @override
  State<EmployeeLayout> createState() => _EmployeeLayoutState();
}

class _EmployeeLayoutState extends State<EmployeeLayout> {
  AuthService authService = AuthService();

  String userName = 'Loading...';
  String userRole = 'Loading...';
  String userEmail = 'Loading...';
  String userDepartment = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

 Future<void> fetchUserProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        userName = 'Guest';
        userRole = 'No Role';
        userEmail = '';
        userDepartment = 'No Department';
      });
      return;
    }

    try {
      final data = await supabase
          .from('employees')
          .select(
              'name, profession, departments(name)') // join with departments table
          .eq('user_id', user.id)
          .maybeSingle();

      setState(() {
        userName = data?['name'] ?? user.email ?? 'No Name';
        userRole = data?['profession'] ?? 'No Role';
        userEmail = user.email ?? '';
        userDepartment = data?['departments']?['name'] ?? 'No Department';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          userName = user.email ?? 'No Name';
          userRole = 'Unknown Role';
          userEmail = user.email ?? '';
          userDepartment = 'No Department';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Employee Dashboard'),
      drawer: CommonDrawer(
        userName: userName,
        userRole: userRole,
        userEmail: userEmail,
        userDepartment: userDepartment,
        onLogout: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            authService.signOut();
          }
        },
      ),
      body: const SalaryReportScreen(),
    );
  }
}
