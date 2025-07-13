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
      });
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, role')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        userName = data?['full_name'] ?? user.email ?? 'No Name';
        userRole = data?['role'] ?? 'No Role';
        userEmail = user.email ?? '';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          userName = user.email ?? 'No Name';
          userRole = 'Unknown Role';
          userEmail = user.email ?? '';
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
