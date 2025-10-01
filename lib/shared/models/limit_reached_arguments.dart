import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@template limit_type}
/// Defines the types of content limits that can be reached by a user.
/// {@endtemplate}
enum LimitType {
  /// Represents the limit for followed topics.
  followedTopics,

  /// Represents the limit for followed sources.
  followedSources,

  /// Represents the limit for followed countries.
  followedCountries,

  /// Represents the limit for saved headlines.
  savedHeadlines,
}

/// {@template limit_reached_arguments}
/// Arguments passed to the [LimitReachedPage] to provide context
/// about the specific limit that was reached.
/// {@endtemplate}
@immutable
class LimitReachedArguments extends Equatable {
  /// {@macro limit_reached_arguments}
  const LimitReachedArguments({
    required this.limitType,
    required this.userRole,
    this.redirectPath,
  });

  /// The type of limit that was reached.
  final LimitType limitType;

  /// The role of the user when the limit was reached.
  final AppUserRole userRole;

  /// The path to redirect to after the user addresses the limit (e.g., signs in).
  final String? redirectPath;

  @override
  List<Object?> get props => [limitType, userRole, redirectPath];
}
