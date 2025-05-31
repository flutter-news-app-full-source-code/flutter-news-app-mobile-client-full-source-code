import 'package:timeago/timeago.dart' as timeago;

/// Custom Arabic lookup messages for the timeago package.
class ArTimeagoMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => ''; // No prefix, will include in string
  @override
  String prefixFromNow() => 'بعد '; // Prefix for future
  @override
  String suffixAgo() => ''; // No suffix
  @override
  String suffixFromNow() => '';

  @override
  String lessThanOneMinute(int seconds) => 'الآن';
  @override
  String aboutAMinute(int minutes) => 'منذ 1د';
  @override
  String minutes(int minutes) => 'منذ ${minutes}د';

  @override
  String aboutAnHour(int minutes) => 'منذ 1س';
  @override
  String hours(int hours) => 'منذ ${hours}س';

  @override
  String aDay(int hours) => 'منذ 1ي'; // Or 'أمس' if preferred for exactly 1 day
  @override
  String days(int days) => 'منذ ${days}ي';

  @override
  String aboutAMonth(int days) => 'منذ 1ش';
  @override
  String months(int months) => 'منذ ${months}ش';

  @override
  String aboutAYear(int year) => 'منذ 1سنة'; // Using سنة for year
  @override
  String years(int years) => 'منذ ${years}سنوات'; // Standard plural

  @override
  String wordSeparator() => ' ';
}
