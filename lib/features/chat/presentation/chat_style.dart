import 'package:flutter/material.dart';

import '../../../app/theme/paths_theme.dart';

const chatGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [PathsTheme.blue, Color(0xFF0B5AA1), Color(0xFF06386B)],
);

String chatTimestamp(BuildContext context, String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return '';
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  final yesterday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 1));
  if (date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day) {
    return 'Yesterday';
  }
  return MaterialLocalizations.of(context).formatShortDate(date);
}

String messageTimestamp(BuildContext context, String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  return date == null
      ? ''
      : MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(date),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );
}
