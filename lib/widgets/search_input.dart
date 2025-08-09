import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:albaderapp/widgets/custom_button.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final int? exactDigits;
  final String label;
  final VoidCallback onSearch;
  final double verticalPadding;
  final double horizontalPadding;
  final double buttonHeight;
  final bool readOnly;
  final bool enabled;

  const SearchInput({
    super.key,
    required this.controller,
    this.exactDigits,
    required this.label,
    required this.onSearch,
    this.verticalPadding = 10,
    this.horizontalPadding = 10,
    this.buttonHeight = 40,
    this.readOnly = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: readOnly || !enabled,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              if (exactDigits != null)
                LengthLimitingTextInputFormatter(exactDigits),
            ],
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter $label';
              } else if (exactDigits != null && value.length != exactDigits) {
                return '$label must be exactly $exactDigits digits';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: horizontalPadding),
        SizedBox(
          height: buttonHeight,
          child: CustomButton(
            label: 'Search',
            onPressed: enabled ? onSearch : null,
            textColor: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
