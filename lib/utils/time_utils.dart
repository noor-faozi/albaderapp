import 'package:flutter/material.dart';

class TimeUtils {
  // Calculates total hours (as double) between two `TimeOfDay`s
  static double? calculateTotalHours(TimeOfDay? inTime, TimeOfDay? outTime) {
    if (inTime == null || outTime == null) return null;

    final inDateTime = DateTime(0, 0, 0, inTime.hour, inTime.minute);
    final outDateTime = DateTime(0, 0, 0, outTime.hour, outTime.minute);
    final diff = outDateTime.difference(inDateTime);

    return diff.inMinutes / 60.0;
  }

  // Formats decimal hours to HH:MM format
  static String formatHoursToHM(double hours) {
    final int h = hours.floor();
    final int m = ((hours - h) * 60).round();
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  // Formats hours
  static String formatTime(String? raw) {
    if (raw == null) return '';
    final parts = raw.split(':');
    return '${parts[0]}:${parts[1]}';
  }
}
