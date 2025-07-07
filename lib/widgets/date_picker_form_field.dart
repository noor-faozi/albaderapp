import 'package:flutter/material.dart';

class DatePickerFormField extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final FormFieldValidator<DateTime>? validator;
  final bool enabled;

  const DatePickerFormField({
    super.key,
    required this.selectedDate,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: validator,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Date:', style: TextStyle(fontSize: 16)),
              TextButton.icon(
                onPressed: enabled
                    ? () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          onChanged(date);
                          field.didChange(date);
                        }
                      }
                    : null,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  selectedDate.toLocal().toString().split(' ')[0],
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled
                        ? null
                        : Colors.grey, // visually indicate disabled state
                  ),
                ),
              ),
            ],
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 4.0),
              child: Text(
                field.errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
