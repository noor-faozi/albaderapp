import 'dart:convert';
import 'package:albaderapp/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:albaderapp/utils/responsive.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/custom_text_form_field.dart';
import 'package:albaderapp/widgets/show_confirm_dialog.dart';

class UserForm extends StatefulWidget {
  final Map<String, dynamic>?
      userRecord; // editing existing user, null = create new
  final void Function()? onSuccess;

  const UserForm({super.key, this.userRecord, this.onSuccess});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _employeeIdController;
  late TextEditingController _passwordController;

  String _role = 'supervisor'; // default
  String? _selectedDepartment;
  bool _isLoading = false;
  String? _employeeIdUniqueError;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.userRecord?['username'] ?? '');
    _fullNameController =
        TextEditingController(text: widget.userRecord?['name'] ?? '');
    _employeeIdController =
        TextEditingController(text: widget.userRecord?['id'] ?? '');
    _passwordController = TextEditingController();

    _role = widget.userRecord?['role'] ?? 'supervisor';
    _selectedDepartment = widget.userRecord?['department_id'];

    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final data = await _fetchDepartments();
    setState(() {
      _departments = data;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generateEmail(String username) {
    return "$username@albadergroup.ae";
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'\d').hasMatch(password)) return false;
    if (!RegExp(r'[!@#\$%&*]').hasMatch(password)) return false;
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

    final supabase = Supabase.instance.client;
    final tablesToCheck = ['supervisors', 'managers', 'employees'];

    bool exists = false;
    for (final table in tablesToCheck) {
      final existing = await supabase
          .from(table)
          .select('id')
          .eq('id', employeeId)
          .maybeSingle();

      if (existing != null) {
        exists = true;
        break;
      }
    }

    setState(() {
      _employeeIdUniqueError =
          exists ? 'Employee ID already exists' : null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    final accessToken = supabase.auth.currentSession?.accessToken;

    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No access token found. Please login again.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final employeeId = _employeeIdController.text.trim();
    final email = _generateEmail(username);
    final now = DateTime.now();

    try {
      String? userId = widget.userRecord?['user_id'];

      if (widget.userRecord == null) {
        // CREATE new user via your edge function
        final response = await http.post(
          Uri.parse(
              'https://twlxilnxparfazvmfoaw.supabase.co/functions/v1/create-employee'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'email': email,
            'password': _passwordController.text,
            'email_confirm': true,
            'email_confirmed_at': now.toIso8601String(),
            'metadata': {
              'role': _role,
              'full_name': fullName,
              'username': username,
            },
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to create user: ${response.body}');
        }

        final data = jsonDecode(response.body);
        userId = data['user']['id'];
        if (userId == null) throw Exception("User creation failed.");

        // Insert into profiles
        await supabase.from('profiles').insert({
          'id': userId,
          'username': username,
          'role': _role,
          'full_name': fullName,
        });

        // Insert into role-specific table
        final roleTable = _role == 'supervisor' ? 'supervisors' : 'managers';
        await supabase.from(roleTable).insert({
          'id': employeeId,
          'user_id': userId,
          'name': fullName,
          'department_id': _selectedDepartment,
          'is_active': true,
        });
      } else {
        // EDIT existing user (update profiles and role table)

        // Update profiles table
        await supabase.from('profiles').update({
          'full_name': fullName,
        }).eq('id', userId as Object);

        // Update role-specific table
        final roleTable = _role == 'supervisor' ? 'supervisors' : 'managers';

        await supabase.from(roleTable).update({
          'name': fullName,
          'department_id': _selectedDepartment,
        }).eq('user_id', userId as Object);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.userRecord == null
              ? 'User created successfully!'
              : 'User updated successfully!'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      if (widget.onSuccess != null) widget.onSuccess!();

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDepartments() async {
    final supabase = Supabase.instance.client;
    final res = await supabase.from('departments').select().order('name');
    if (res is List) {
      return res.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    double padding = screenPadding(context, 0.05);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userRecord == null
                  ? 'Add a new supervisor or manager by filling in the details below.'
                  : 'Update the user details as needed.',
              style: TextStyle(
                fontSize: screenPadding(context, 0.035),
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: screenPadding(context, 0.06)),

            // Employee ID
            CustomTextFormField(
              controller: _employeeIdController,
              keyboardType: TextInputType.number,
              labelText: "Employee ID (3 digits)",
              prefixIcon: const Icon(Icons.badge_outlined),
              isReadOnly: widget.userRecord != null,
              validator: _validateEmployeeId,
              onChanged: (val) {
                if (widget.userRecord == null) {
                  _checkEmployeeIdUnique(val.trim());
                }
              },
            ),
            SizedBox(height: screenPadding(context, 0.04)),
            // Full Name
            CustomTextFormField(
              controller: _fullNameController,
              prefixIcon: const Icon(Icons.badge),
              labelText: "Full Name",
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Full Name is required";
                }
                return null;
              },
            ),
            SizedBox(height: screenPadding(context, 0.04)),

            // Username - readonly if editing
            CustomTextFormField(
              controller: _usernameController,
              isReadOnly: widget.userRecord != null,
              keyboardType: TextInputType.text,
              labelText: "Username",
              prefixIcon: const Icon(Icons.person),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Username is required";
                }
                if (value.trim().length < 3) {
                  return "Username must be at least 3 characters";
                }
                return null;
              },
            ),
            SizedBox(height: screenPadding(context, 0.04)),

            // Role dropdown
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(
                    value: 'supervisor', child: Text('Supervisor')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
              ],
              onChanged: widget.userRecord != null
                  ? null
                  : (val) {
                      if (val != null) setState(() => _role = val);
                    },
              decoration: InputDecoration(
                labelText: 'Role',
                prefixIcon: const Icon(
                  Icons.business_center_rounded,
                  color: gray500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: gray500,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: firstColor,
                    width: 1.8,
                  ),
                ),
              ),
            ),
            SizedBox(height: screenPadding(context, 0.04)),

            // Department dropdown
            _departments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    items: _departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept['id'] as String,
                        child: Text(dept['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                            setState(() {
                              _selectedDepartment = val;
                            });
                          },
                    decoration: InputDecoration(
                      labelText: 'Department',
                      prefixIcon: const Icon(
                        Icons.apartment_rounded,
                        color: gray500,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: gray500,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: firstColor,
                          width: 1.8,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please select a department';
                      }
                      return null;
                    },
                  ),
            SizedBox(height: screenPadding(context, 0.04)),

            // Email only on create
            if (widget.userRecord == null) ...[
              CustomTextFormField(
                controller: _passwordController,
                isPassword: true,
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Password is required";
                  }
                  if (!_isStrongPassword(value.trim())) {
                    return "Password must be at least 8 chars, include upper, lower, digit & special char";
                  }
                  return null;
                },
              ),
              SizedBox(height: screenPadding(context, 0.04)),
            ],

            Center(
              child: CustomButton(
                label: _isLoading
                    ? 'Loading...'
                    : widget.userRecord != null
                        ? 'Update User'
                        : 'Create User',
                widthFactor: 0.8,
                heightFactor: 0.1,
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (await showConfirmDialog(
                          context,
                          widget.userRecord == null
                              ? 'Are you sure you want to create this user?'
                              : 'Are you sure you want to update this user?',
                        )) {
                          await _submitForm();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
