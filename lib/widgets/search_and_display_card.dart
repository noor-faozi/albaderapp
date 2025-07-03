import 'dart:ui';

import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchAndDisplayCard<T> extends StatelessWidget {
  final TextEditingController controller;
  final int? exactDigits;
  final String label;
  final VoidCallback onSearch;
  final T? data;
  final bool notFound;
  final Widget Function(T data) detailsBuilder;
  final double verticalPadding;
  final double horizontalPadding;
  final double buttonHeight;

  const SearchAndDisplayCard({
    Key? key,
    required this.controller,
    this.exactDigits,
    required this.label,
    required this.onSearch,
    required this.data,
    required this.notFound,
    required this.detailsBuilder,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.buttonHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, 
                  if (exactDigits != null)
                    LengthLimitingTextInputFormatter(exactDigits),
                ],
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(width: 0.1,),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: horizontalPadding,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter $label';
                  } else if (value.length != exactDigits) {
                    return '$label must be exactly $exactDigits digits';
                  }
                  return null; // valid
                },
              ),
            ),
            SizedBox(width: horizontalPadding),
            SizedBox(
              height: buttonHeight,
              child: CustomButton(
                label: 'Search',
                onPressed: onSearch,
                textColor: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (data != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: SizedBox(
              width: double.infinity,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: detailsBuilder(data!),
                ),
              ),
            ),
          ),
        ] else if (notFound) ...[
          Padding(
            padding: EdgeInsets.all(verticalPadding),
            child: Text(
              'No $label found with this code.',
              style: const TextStyle(
                  color: red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}
