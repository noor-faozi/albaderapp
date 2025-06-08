import 'package:flutter/material.dart';

class CustomSecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomSecondaryAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Colors.black,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(title),
      centerTitle: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.2),
      titleTextStyle: const TextStyle(
          color: Colors.black, fontSize: 20, fontWeight: FontWeight.w500),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}