// lib/widgets/form_card_wrapper.dart
import 'package:albaderapp/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:albaderapp/theme/colors.dart';

class FormCardWrapper extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry? padding;

  const FormCardWrapper({
    super.key,
    required this.child,
    this.elevation = 10,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: gray500, width: 0.3),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(screenPadding(context, 0.06)),
        child: child,
      ),
    );
  }
}
