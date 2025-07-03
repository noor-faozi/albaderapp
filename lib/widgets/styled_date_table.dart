import 'package:flutter/material.dart';

class StyledDataTable extends StatelessWidget {
  final Widget child;

  const StyledDataTable({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DataTableTheme(
      data: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
        headingTextStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: Colors.black87),
        dividerThickness: 0.5,
        dataRowColor: WidgetStateProperty.all(Colors.white),
      ),
      child: child,
    );
  }
}
