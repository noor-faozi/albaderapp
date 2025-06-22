import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddHolidayScreen extends StatefulWidget {
  const AddHolidayScreen({super.key});

  @override
  State<AddHolidayScreen> createState() => _AddHolidayScreenState();
}

class _AddHolidayScreenState extends State<AddHolidayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final  _descriptionController = TextEditingController(); 
  DateTime selectedDate = DateTime.now();
  final String? createdBy = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}