import 'package:core/core.dart';
import 'package:equatable/equatable.dart';

/// {@template decorator_placeholder}
/// A stateless [FeedItem] that acts as a marker for a non-ad decorator slot
/// in the feed.
///
/// This model is used in the BLoC's state to indicate where a dynamic
/// decorator (like a call-to-action or content collection) should be
/// displayed, without holding the actual stateful decorator widget. The actual
/// loading and display logic is handled by a dedicated loader widget that
/// renders this placeholder.
/// {@endtemplate}
class DecoratorPlaceholder extends FeedItem with EquatableMixin {
  /// {@macro decorator_placeholder}
  const DecoratorPlaceholder({required this.id})
    : super(type: 'decorator_placeholder');

  /// A unique identifier for this specific placeholder instance.
  final String id;

  @override
  List<Object?> get props => [id, type];
}
