import 'package:albaderapp/auth/auth_service.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final authService = AuthService();

  CustomAppBar({
    super.key,
    required this.title,
  });

  void logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontSize: 22),),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      titleTextStyle: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: logout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
