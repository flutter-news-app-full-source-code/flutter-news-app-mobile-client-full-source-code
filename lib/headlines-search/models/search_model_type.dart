/// Defines the types of models that can be searched.
enum SearchModelType {
  headline,
  category,
  // country, // Removed
  source;

  /// Returns a user-friendly display name for the enum value.
  ///
  /// This should ideally be localized using context.l10n,
  /// but for simplicity in this step, we'll use direct strings.
  /// TODO(Cline): Localize these display names.
  String get displayName {
    switch (this) {
      case SearchModelType.headline:
        return 'Headlines';
      case SearchModelType.category:
        return 'Categories';
      // case SearchModelType.country: // Removed
      //   return 'Countries'; // Removed
      case SearchModelType.source:
        return 'Sources';
    }
  }

  /// Returns the string representation for API query parameters.
  String toJson() => name;
}
