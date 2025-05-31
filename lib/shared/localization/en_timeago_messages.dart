import 'package:timeago/timeago.dart' as timeago;

/// Custom English lookup messages for the timeago package (concise).
class EnTimeagoMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => ''; // No prefix
  @override
  String prefixFromNow() => ''; // No prefix
  @override
  String suffixAgo() => ' ago'; // Suffix instead
  @override
  String suffixFromNow() => ' from now'; // Suffix instead

  @override
  String lessThanOneMinute(int seconds) => 'now';
  @override
  String aboutAMinute(int minutes) => '1m';
  @override
  String minutes(int minutes) => '${minutes}m';

  @override
  String aboutAnHour(int minutes) => '1h';
  @override
  String hours(int hours) => '${hours}h';

  @override
  String aDay(int hours) => '1d';
  @override
  String days(int days) => '${days}d';

  @override
  String aboutAMonth(int days) => '1mo';
  @override
  String months(int months) => '${months}mo';

  @override
  String aboutAYear(int year) => '1y';
  @override
  String years(int years) => '${years}y';

  @override
  String wordSeparator() => ' ';
}
