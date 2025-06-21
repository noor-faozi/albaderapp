import 'package:albaderapp/layouts/admin_layout.dart';
import 'package:albaderapp/screens/admin/login_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: firstColor,
                ),
              ),
            );
          }

          // check if there ia a valid session currently
          final session = snapshot.hasData ? snapshot.data!.session : null;

          if (session != null) {
            return AdminLayout();
          } else {
            return LoginScreen();
          }
        });
  }
}
