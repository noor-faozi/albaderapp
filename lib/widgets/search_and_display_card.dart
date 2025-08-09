import 'dart:ui';

import 'package:albaderapp/theme/colors.dart';
import 'package:albaderapp/widgets/custom_button.dart';
import 'package:albaderapp/widgets/search_input.dart';
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
  final bool readOnly;
  final bool enabled;

  const SearchAndDisplayCard({
    super.key,
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
    this.readOnly = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchInput(
          controller: controller,
          exactDigits: exactDigits,
          label: label,
          onSearch: onSearch,
          verticalPadding: verticalPadding,
          horizontalPadding: horizontalPadding,
          buttonHeight: buttonHeight,
          readOnly: readOnly,
          enabled: enabled,
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
