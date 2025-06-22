import 'package:flutter/material.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});

  @override
  State<HolidaysScreen> createState() => _HolidaysState();
}

class _HolidaysState extends State<HolidaysScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin HolidaysScreen'));
  }
}