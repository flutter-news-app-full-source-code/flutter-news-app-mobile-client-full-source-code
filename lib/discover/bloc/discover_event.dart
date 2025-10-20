part of 'discover_bloc.dart';

/// Base class for all events related to the [DiscoverBloc].
sealed class DiscoverEvent extends Equatable {
  /// {@macro discover_event}
  const DiscoverEvent();

  @override
  List<Object> get props => [];
}

/// {@template discover_started}
/// Event added when the discover feature is first started.
/// This triggers the initial fetch of all available sources.
/// {@endtemplate}
final class DiscoverStarted extends DiscoverEvent {}
