import 'package:albaderapp/theme/colors.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double widthFactor;
  final double heightFactor;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.widthFactor = 0.25,
    this.heightFactor = 0.06,
  });

  double screenPadding(BuildContext context, double factor) {
    return MediaQuery.of(context).size.width * factor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: screenPadding(context, heightFactor),
      width: screenPadding(context, widthFactor),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: gray500, width: 0.25),
          elevation: 4,
        ),
        child: Text(label),
      ),
    );
  }
}
