import 'dart:math';

import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/utils/responsive.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _salaryController = TextEditingController();
  final _allowanceController = TextEditingController();

  bool _isLoading = false;
  String? _generatedUsername;
  String? _generatedPassword;
  bool _showPassword = false;
  String? _employeeIdUniqueError;

  bool _usernameManuallyEdited = false;
  bool _passwordManuallyEdited = false;

  @override
  void initState() {
    super.initState();

    _usernameController.addListener(() {
      _usernameManuallyEdited = true;
    });

    _passwordController.addListener(() {
      _passwordManuallyEdited = true;
    });

    _nameController.addListener(() {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) {
        final username = _generateUsername(name);
        final password = _generatePassword();

        setState(() {
          if (!_usernameManuallyEdited) {
            _usernameController.text = username;
          }
          if (!_passwordManuallyEdited) {
            _passwordController.text = password;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _nameController.dispose();
    _professionController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _salaryController.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Employees"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(
                      screenPadding(context, 0.05)),
                  child: const Text(
                    "Add New Employee",
                    style: TextStyle(fontSize: 20),
                  ),
                ),

                CustomTextFormField(
                  controller: _employeeIdController,
                  labelText: "Employee ID (3 digits)",
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  validator: _validateEmployeeId,
                  onChanged: _checkEmployeeIdUnique,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  prefixIcon: const Icon(Icons.badge_rounded),
                ),
                SizedBox(height: screenHeight(context, 0.015)),
                CustomTextFormField(
                  controller: _nameController,
                  labelText: "Full Name",
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter name" : null,
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                SizedBox(height: screenHeight(context, 0.025)),
                CustomTextFormField(
                  controller: _usernameController,
                  labelText: "Username",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter username";
                    }
                    // Check username contains at least one number
                    if (!RegExp(r'\d').hasMatch(value)) {
                      return "Username must contain at least one number";
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                SizedBox(height: screenHeight(context, 0.025)),
                CustomTextFormField(
                  controller: _passwordController,
                  labelText: 'Password',
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter password';
                    if (!_isStrongPassword(val)) {
                      return 'Password must be at least 8 characters, include uppercase, lowercase, number, and special character';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight(context, 0.025)),
                CustomTextFormField(
                  controller: _professionController,
                  labelText: "Profession",
                  validator: (value) => value == null || value.isEmpty
                      ? "Enter Profession"
                      : null,
                  prefixIcon: const Icon(Icons.business_center_rounded),
                ),
                SizedBox(height: screenHeight(context, 0.025)),
                CustomTextFormField(
                  controller: _salaryController,
                  labelText: "Salary (AED)",
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}$|^\d*\.?$'),
                    ),
                  ],
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter Salary" : null,
                  prefixIcon: const Icon(Icons.payments_rounded),
                ),
                SizedBox(height: screenHeight(context, 0.025)),
                CustomTextFormField(
                  controller: _allowanceController,
                  labelText: "Allowance (AED)",
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}$|^\d*\.?$'),
                    ),
                  ],
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter Allowance" : null,
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                SizedBox(height: screenHeight(context, 0.035)),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateEmployee,
                  child: const Text("Create Employee"),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    final employeeId = _employeeIdController.text.trim();
    final name = _capitalizeEachWord(_nameController.text.trim());
    final profession = _capitalizeEachWord(_professionController.text.trim());
    final username = _usernameController.text.trim().toLowerCase();
    final email = _generateEmail(username);
    final password = _passwordController.text;
    final salaryText = _salaryController.text.trim();
    final allowanceText = _allowanceController.text.trim();

    final double? salary = double.tryParse(salaryText);
    final double? allowance = double.tryParse(allowanceText);

    try {
      final authRes =
          await supabase.auth.signUp(email: email, password: password);
      final userId = authRes.user?.id;
      if (userId == null) throw Exception("User creation failed");

      await supabase.from('profiles').insert({
        'id': userId,
        'username': username,
        'role': 'employee',
        'full_name': name,
      });

      await supabase.from('employees').insert({
        'id': employeeId,
        'user_id': userId,
        'name': name,
        'profession': profession,
        'salary': salary,
        'allowance': allowance
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee created successfully!')),
      );

      // Clear form
      _employeeIdController.clear();
      _nameController.clear();
      _professionController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _salaryController.clear();
      _allowanceController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateUsername(String name) {
    final base = name.toLowerCase().replaceAll(RegExp(r'\s+'), '.');
    final randNumbers = Random().nextInt(9000) + 1000; // 4 digit number
    return "$base$randNumbers";
  }

  String _generateEmail(String username) {
    return "$username@albader.com";
  }

  String _generatePassword({int length = 10}) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const digits = '0123456789';
    const specialChars = '!@#\$%&*';
    const allChars = uppercase + lowercase + digits + specialChars;
    const lettersAndDigits = uppercase + lowercase + digits;

    final rand = Random.secure();

    // Pick one from each required category
    final upper = uppercase[rand.nextInt(uppercase.length)];
    final lower = lowercase[rand.nextInt(lowercase.length)];
    final digit = digits[rand.nextInt(digits.length)];
    final special = specialChars[rand.nextInt(specialChars.length)];

    // First char must be alphanumeric
    final firstChar = lettersAndDigits[rand.nextInt(lettersAndDigits.length)];

    // Fill the rest of the password
    List<String> rest = List.generate(length - 5, (_) {
      return allChars[rand.nextInt(allChars.length)];
    });

    // Add required character types (except firstChar, already included)
    rest.addAll([upper, lower, digit, special]);

    // Shuffle the rest (excluding the first character)
    rest.shuffle(rand);

    return firstChar + rest.join();
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false; // Uppercase
    if (!RegExp(r'[a-z]').hasMatch(password)) return false; // Lowercase
    if (!RegExp(r'\d').hasMatch(password)) return false; // Digit
    if (!RegExp(r'[!@#\$%&*]').hasMatch(password)) return false; // Special char
    return true;
  }

  String? _validateEmployeeId(String? value) {
    if (value == null || !RegExp(r'^\d{3}$').hasMatch(value)) {
      return 'Employee ID must be exactly 3 digits';
    }

    if (_employeeIdUniqueError != null) {
      return _employeeIdUniqueError;
    }
    return null;
  }

  Future<void> _checkEmployeeIdUnique(String employeeId) async {
    if (!RegExp(r'^\d{3}$').hasMatch(employeeId)) return;

    final existing = await Supabase.instance.client
        .from('employees')
        .select()
        .eq('id', employeeId)
        .maybeSingle();

    setState(() {
      _employeeIdUniqueError =
          existing != null ? 'Employee ID already exists' : null;
    });
  }

  String _capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }
}
