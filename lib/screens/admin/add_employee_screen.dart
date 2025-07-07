import 'dart:math';

import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:albaderapp/widgets/form_card_wrapper.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/utils/responsive.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic>? employeeRecord; // For editing

  const AddEmployeeScreen({super.key, this.employeeRecord});

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

    // If editing an existing employee, pre-fill the form
    if (widget.employeeRecord != null) {
      final record = widget.employeeRecord!;
      _employeeIdController.text = record['id'].toString();
      _nameController.text = record['name'] ?? '';
      _professionController.text = record['profession'] ?? '';
      _usernameController.text = record['username'] ?? '';
      _salaryController.text = record['salary']?.toString() ?? '';
      _allowanceController.text = record['allowance']?.toString() ?? '';

      // Avoid overwriting the username/password on name change
      _usernameManuallyEdited = true;
      _passwordManuallyEdited = true;
    }

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
          padding: EdgeInsets.all(screenPadding(context, 0.04)),
          child: Form(
            key: _formKey,
            child: FormCardWrapper(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(screenPadding(context, 0.05)),
                    child: const Text(
                      "Add New Employee",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.7),
                    ),
                  ),
                  CustomTextFormField(
                    controller: _employeeIdController,
                    labelText: "Employee ID (3 digits)",
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    isReadOnly: widget.employeeRecord != null,
                    validator: _validateEmployeeId,
                    onChanged: widget.employeeRecord == null
                        ? _checkEmployeeIdUnique
                        : null,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  if (widget.employeeRecord == null) ...[
                    CustomTextFormField(
                      controller: _usernameController,
                      labelText: "Username",
                      isReadOnly: widget.employeeRecord != null,
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
                      isReadOnly: widget.employeeRecord != null,
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
                  ],
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
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter Allowance"
                        : null,
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  SizedBox(height: screenHeight(context, 0.035)),
                  CustomButton(
                    label: _isLoading
                        ? 'Loading...'
                        : widget.employeeRecord != null
                            ? 'Update Employee'
                            : 'Add Employee',
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (await showConfirmDialog(context,
                                'Are you sure you want to submit this record?')) {
                              _handleCreateEmployee();
                            }
                          },
                    widthFactor: 0.8,
                    heightFactor: 0.1,
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: firstColor),
                  ],
                ],
              ),
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
    final isEdit = widget.employeeRecord != null;

    try {
      if (isEdit) {
        final id = widget.employeeRecord!['id'];

        await supabase.from('employees').update({
          'name': name,
          'profession': profession,
          'salary': salary,
          'allowance': allowance,
        }).eq('id', id);

        // update profile name
        final userId = widget.employeeRecord!['user_id'];
        if (userId != null) {
          await supabase.from('profiles').update({
            'full_name': name,
          }).eq('id', userId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Employee updated successfully.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context);
      } else {
        final authRes =
            await supabase.auth.signUp(email: email, password: password);
        final userId = authRes.user?.id;
        if (userId == null) throw Exception("User creation failed.");

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
          SnackBar(
            content: const Text('Employee created successfully.'),
            backgroundColor: Colors.green.shade700,
          ),
        );

        Navigator.pop(context);
      }
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
