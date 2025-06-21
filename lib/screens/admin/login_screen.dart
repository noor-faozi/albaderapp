import 'package:albaderapp/auth/auth_service.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // login function
  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    try {
      final response =
          await authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // email
          CustomTextField(
            controller: _emailController,
            prefixIcon: const Icon(Icons.person_rounded),
            hintText: "Enter your email",
          ),

          // password
          CustomTextField(
            controller: _passwordController,
            prefixIcon: const Icon(Icons.lock_rounded),
            obscureText: true,
            hintText: "Enter your password",
          ),

          // button
          CustomButton(onPressed: login, label: "Login"),
        ],
      ),
    );
  }
}
