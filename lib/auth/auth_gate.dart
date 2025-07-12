import 'package:albaderapp/layouts/admin_layout.dart';
import 'package:albaderapp/layouts/manager_layout.dart';
import 'package:albaderapp/layouts/supervisor_layout.dart';
import 'package:albaderapp/screens/admin/login_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // While checking the auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: firstColor),
            ),
          );
        }

        // Get session
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session == null) {
          return const LoginScreen();
        }

        // Now fetch role using FutureBuilder
        return FutureBuilder(
          future: Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .single(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: firstColor),
                ),
              );
            }

            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: Text('Error loading user role')),
              );
            }

            final role = roleSnapshot.data!['role'];

            switch (role) {
              case 'admin':
                return const AdminLayout();
              case 'manager':
                return const ManagerLayout();
              case 'supervisor':
                return const SupervisorLayout();
              // case 'employee':
              //   return EmployeeLayout();
              default:
                return const Scaffold(
                  body: Center(child: Text('Unknown role')),
                );
            }
          },
        );
      },
    );
  }

}
