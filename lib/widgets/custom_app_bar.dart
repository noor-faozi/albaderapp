import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
      );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}