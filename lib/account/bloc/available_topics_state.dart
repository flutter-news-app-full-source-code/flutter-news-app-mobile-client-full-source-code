part of 'available_topics_bloc.dart';

sealed class AvailableTopicsState extends Equatable {
  const AvailableTopicsState();
  
  @override
  List<Object> get props => [];
}

final class AvailableTopicsInitial extends AvailableTopicsState {}
