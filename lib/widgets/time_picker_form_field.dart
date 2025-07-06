import 'package:flutter/material.dart';

class TimePickerFormField extends FormField<TimeOfDay> {
  TimePickerFormField({
    super.key,
    required String label,
    required TimeOfDay? initialValue,
    required ValueChanged<TimeOfDay> onTimePicked,
    FormFieldValidator<TimeOfDay>? validator,
  }) : super(
          initialValue: initialValue,
          validator: validator ?? (value) => value == null ? 'Required' : null,
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 16)),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: field.context,
                          initialTime: field.value ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          onTimePicked(picked);
                          field.didChange(picked); // update form field
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        field.value == null
                            ? 'Select Time'
                            : field.value!.format(field.context),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );
}
