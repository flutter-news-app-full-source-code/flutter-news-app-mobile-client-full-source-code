import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_news_app_mobile_client_full_source_code/app/bloc/app_bloc.dart';

/// Extension on [Map<SupportedLanguage, String>] to provide safe access
/// to localized strings based on the backend's projection logic.
extension MultilingualMapX on Map<SupportedLanguage, String> {
  /// Returns the localized string for the current context.
  ///
  /// If the map is empty, returns an empty string.
  /// If the map is "projected" (contains only one entry from the backend),
  /// it returns that entry's value.
  /// If the map contains multiple entries (raw data), it attempts to find
  /// the one matching the current app language.
  String getValue(BuildContext context) {
    if (isEmpty) return '';

    // If the backend projected the data (List Views), it only sent one pair.
    if (length == 1) return values.first;

    // Fallback logic for raw data.
    // We look up the current language from the AppBloc.
    final appLanguage = context.read<AppBloc>().state.settings?.language;
    if (appLanguage != null && containsKey(appLanguage)) {
      return this[appLanguage]!;
    }

    // Ultimate fallback: English or the first available translation.
    return this[SupportedLanguage.en] ?? values.first;
  }
}