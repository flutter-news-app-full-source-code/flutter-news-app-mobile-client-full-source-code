part of 'initial_personalization_bloc.dart';

sealed class InitialPersonalizationEvent extends Equatable {
  const InitialPersonalizationEvent();

  @override
  List<Object> get props => [];
}

final class InitialPersonalizationDataRequested
    extends InitialPersonalizationEvent {}

final class InitialPersonalizationItemsSelected<T>
    extends InitialPersonalizationEvent {
  const InitialPersonalizationItemsSelected({required this.items});

  final Set<T> items;

  @override
  List<Object> get props => [items];
}

final class InitialPersonalizationCompleted
    extends InitialPersonalizationEvent {}

final class InitialPersonalizationSkipped extends InitialPersonalizationEvent {}
