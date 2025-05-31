import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Formats the given [dateTime] into a relative time string
/// (e.g., "5m ago", "Yesterday", "now").
///
/// Uses the current locale from [context] to format appropriately.
/// Returns an empty string if [dateTime] is null.
String formatRelativeTime(BuildContext context, DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }
  final locale = Localizations.localeOf(context).languageCode;
  return timeago.format(dateTime, locale: locale);
}
