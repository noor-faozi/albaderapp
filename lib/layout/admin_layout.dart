import 'package:albaderapp/screens/admin/attendance.dart';
import 'package:albaderapp/screens/admin/employees.dart';
import 'package:albaderapp/screens/admin/holidays.dart';
import 'package:albaderapp/screens/admin/overtime_attendance.dart';
import 'package:albaderapp/screens/admin/reports.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Employees(),
    const Attendance(),
    const OvertimeAttendance(),
    const Holidays(),
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
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.groups), label: 'Employees'),
          BottomNavigationBarItem(
              icon: Icon(Icons.punch_clock), label: 'Attendance'),
          BottomNavigationBarItem(
              icon: Icon(Icons.more_time), label: 'Overtime'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event), label: 'Holiday'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Reports'),
        ],
      ),
    );
  }
}