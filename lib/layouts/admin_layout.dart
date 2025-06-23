import 'package:albaderapp/screens/admin/attendance_screen.dart';
import 'package:albaderapp/screens/admin/employees_screen.dart';
import 'package:albaderapp/screens/admin/holidays_screen.dart';
import 'package:albaderapp/screens/admin/overtime_attendance.dart';
import 'package:albaderapp/screens/admin/reports.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EmployeesScreen(),
    const AttendanceScreen(),
    const OvertimeAttendance(),
    const HolidaysScreen(),
    const Reports()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
