import 'package:albaderapp/auth/auth_service.dart';
import 'package:albaderapp/utils/responsive.dart';
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
      body: Column(
        children: [
          // Image at the absolute top
          Image.asset(
            'assets/images/login_background.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // Scrollable login form below image
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenPadding(context, 0.06)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/albader_group_logo.png',
                        height: screenHeight(context, 0.2),
                      ),
                      SizedBox(height: screenHeight(context, 0.04)),
                      // Email
                      CustomTextField(
                        controller: _emailController,
                        prefixIcon: const Icon(Icons.person_rounded),
                        hintText: "Enter your email",
                      ),
                      SizedBox(height: screenHeight(context, 0.025)),

                      // Password
                      CustomTextField(
                        controller: _passwordController,
                        prefixIcon: const Icon(Icons.lock_rounded),
                        obscureText: true,
                        hintText: "Enter your password",
                      ),
                      SizedBox(height: screenHeight(context, 0.03)),

                      // Login button
                      CustomButton(
                        onPressed: login,
                        label: "Login",
                        heightFactor: 0.12,
                        widthFactor: 0.9
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
