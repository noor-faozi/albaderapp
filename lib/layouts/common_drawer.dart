import 'package:albaderapp/screens/admin/configurations_screen.dart';
import 'package:albaderapp/theme/colors.dart';
import 'package:flutter/material.dart';

class CommonDrawer extends StatelessWidget {
  final String userName;
  final String userRole;
  final String userEmail;
  final String? userDepartment;
  final VoidCallback onLogout;
  final VoidCallback? onConfigurations;

  const CommonDrawer({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userEmail,
    this.userDepartment,
    required this.onLogout,
    this.onConfigurations,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [firstColor, firstColorLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName.trim()[0].toUpperCase() : '',
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (userDepartment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${userDepartment!} Department',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  userRole,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Configurations option (only for Admin)
          if (userRole.toLowerCase() == 'admin')
            ListTile(
              leading: const Icon(Icons.settings, color: firstColor),
              title: const Text(
                'Configurations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: onConfigurations ??
                  () {
                    Navigator.pop(context); // close the drawer first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfigurationsScreen(),
                      ),
                    );
                  },
            ),

          const Spacer(),

          // Logout button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.redAccent,
                elevation: 5,
                shadowColor: Colors.red.shade200,
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: onLogout,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
