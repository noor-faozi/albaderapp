import 'package:albaderapp/auth/auth_service.dart';
import 'package:albaderapp/screens/admin/attendance_screen.dart';
import 'package:albaderapp/screens/admin/employees_screen.dart';
import 'package:albaderapp/screens/admin/holidays_screen.dart';
import 'package:albaderapp/screens/admin/overtime_attendance_screen.dart';
import 'package:albaderapp/screens/admin/report_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'common_drawer.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  AuthService authService = AuthService();
  int _selectedIndex = 0;

  String userName = 'Loading...';
  String userRole = 'Loading...';
  String userEmail = 'Loading...';

  final List<Widget> _screens = [
    const EmployeesScreen(),
    const AttendanceScreen(),
    const OvertimeAttendanceScreen(),
    const HolidaysScreen(),
    const ReportScreen()
  ];

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

  String getTitle(int index) {
    switch (index) {
      case 0:
        return 'Employees';
      case 1:
        return 'Attendance';
      case 2:
        return 'Overtime';
      case 3:
        return 'Holiday';
      case 4:
        return 'Labour Cost Report';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: getTitle(_selectedIndex)),
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: gray500,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? Icons.groups : Icons.groups_outlined,
            ),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1
                  ? Icons.punch_clock
                  : Icons.punch_clock_outlined,
            ),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2 ? Icons.more_time : Icons.more_time_outlined,
            ),
            label: 'Overtime',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 3 ? Icons.event : Icons.event_outlined,
            ),
            label: 'Holiday',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 4 ? Icons.analytics : Icons.analytics_outlined,
            ),
            label: 'Report',
          ),
        ],
      ),
    );
  }
}
