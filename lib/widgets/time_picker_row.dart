import 'package:flutter/material.dart';

class TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onTimePicked;

  const TimePickerRow({
    super.key,
    required this.label,
    required this.time,
    required this.onTimePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        TextButton.icon(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (picked != null) {
              onTimePicked(picked);
            }
          },
          icon: const Icon(Icons.access_time),
          label: Text(
            time == null ? 'Select Time' : time!.format(context),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
