import 'package:albaderapp/layouts/admin_layout.dart';
import 'package:albaderapp/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://twlxilnxparfazvmfoaw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3bHhpbG54cGFyZmF6dm1mb2F3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNzU5MTQsImV4cCI6MjA2Mzc1MTkxNH0.1vwhTiSMIAoNozaO3BnNCwOSRNXl3-hzMHugYzPF2kg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AL BADER APP',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const AdminLayout(),
    );
  }
}