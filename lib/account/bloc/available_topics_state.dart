part of 'available_topics_bloc.dart';

enum AvailableTopicsStatus { initial, loading, success, failure }

class AvailableTopicsState extends Equatable {
  const AvailableTopicsState({
    this.status = AvailableTopicsStatus.initial,
    this.availableTopics = const [],
    this.error,
  });

  final AvailableTopicsStatus status;
  final List<Topic> availableTopics;
  final String? error;

  AvailableTopicsState copyWith({
    AvailableTopicsStatus? status,
    List<Topic>? availableTopics,
    String? error,
    bool clearError = false,
  }) {
    return AvailableTopicsState(
      status: status ?? this.status,
      availableTopics: availableTopics ?? this.availableTopics,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        availableTopics,
        error,
      ];
}
