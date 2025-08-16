import 'package:albaderapp/screens/admin/departments_screen.dart';
import 'package:albaderapp/screens/admin/projects_screen.dart';
import 'package:albaderapp/screens/admin/users_screen.dart';
import 'package:albaderapp/screens/admin/work_orders_screen.dart';
import 'package:albaderapp/widgets/custom_secondary_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/utils/responsive.dart';

class ConfigurationsScreen extends StatefulWidget {
  const ConfigurationsScreen({super.key});

  @override
  State<ConfigurationsScreen> createState() => _ConfigurationsScreenState();
}

class _ConfigurationsScreenState extends State<ConfigurationsScreen> {
  @override
  Widget build(BuildContext context) {
    final padding = screenPadding(context, 0.04);
    final iconSize = screenWidth(context, 0.07);
    final fontSize = screenWidth(context, 0.045);

    return Scaffold(
      appBar: const CustomSecondaryAppBar(title: "Configurations"),
      body: ListView(
        children: [
          _buildConfigTile(
            context,
            icon: Icons.business,
            iconColor: Colors.blue,
            title: "Projects",
            fontSize: fontSize,
            iconSize: iconSize,
            padding: padding,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProjectsScreen()),
              );
            },
          ),
          _buildConfigTile(
            context,
            icon: Icons.assignment,
            iconColor: Colors.green,
            title: "Work Orders",
            fontSize: fontSize,
            iconSize: iconSize,
            padding: padding,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkOrdersScreen()),
              );
            },
          ),
          _buildConfigTile(
            context,
            icon: Icons.apartment,
            iconColor: Colors.orange,
            title: "Departments",
            fontSize: fontSize,
            iconSize: iconSize,
            padding: padding,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DepartmentsScreen()),
              );
            },
          ),
          _buildConfigTile(
            context,
            icon: Icons.supervisor_account,
            iconColor: Colors.purple,
            title: "Supervisors and Managers",
            fontSize: fontSize,
            iconSize: iconSize,
            padding: padding,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UsersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required double fontSize,
    required double iconSize,
    required double padding,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: padding * 0.9, horizontal: padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              SizedBox(width: padding),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: iconSize * 0.8, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
