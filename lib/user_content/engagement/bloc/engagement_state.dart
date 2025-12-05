part of 'engagement_bloc.dart';

/// The status of the engagement feature.
enum EngagementStatus {
  /// Initial state, no data loaded.
  initial,

  /// Data is being loaded.
  loading,

  /// Data has been successfully loaded.
  success,

  /// An error occurred while loading data.
  failure,

  /// An engagement action (post, update) is in progress.
  actionInProgress,
}

/// {@template engagement_state}
/// The state of the engagement feature for a single headline.
/// {@endtemplate}
class EngagementState extends Equatable {
  /// {@macro engagement_state}
  const EngagementState({
    this.status = EngagementStatus.initial,
    this.engagements = const [],
    this.userEngagement,
    this.limitationStatus = LimitationStatus.allowed,
    this.error,
  });

  /// The current status of the engagement data.
  final EngagementStatus status;

  /// The list of all engagements for the headline.
  final List<Engagement> engagements;

  /// The current user's engagement for the headline, if any.
  final Engagement? userEngagement;

  /// The status of the content limitation check.
  final LimitationStatus limitationStatus;

  /// The error that occurred, if any.
  final HttpException? error;

  @override
  List<Object?> get props => [
    status,
    engagements,
    userEngagement,
    limitationStatus,
    error,
  ];

  /// Creates a copy of this state with the given fields replaced.
  EngagementState copyWith({
    EngagementStatus? status,
    List<Engagement>? engagements,
    Engagement? userEngagement,
    HttpException? error,
    LimitationStatus? limitationStatus,
    bool clearUserEngagement = false,
  }) {
    return EngagementState(
      status: status ?? this.status,
      engagements: engagements ?? this.engagements,
      userEngagement: clearUserEngagement
          ? null
          : userEngagement ?? this.userEngagement,
      limitationStatus: limitationStatus ?? this.limitationStatus,
      error: error ?? this.error,
    );
  }
}
