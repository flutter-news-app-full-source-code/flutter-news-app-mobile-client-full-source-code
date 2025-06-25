import 'package:timeago/timeago.dart' as timeago;

/// Custom Arabic lookup messages for the timeago package.
class ArTimeagoMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => 'بعد ';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';

  @override
  String lessThanOneMinute(int seconds) => 'الآن';
  @override
  String aboutAMinute(int minutes) => 'منذ 1د';
  @override
  String minutes(int minutes) => 'منذ $minutesد';

  @override
  String aboutAnHour(int minutes) => 'منذ 1س';
  @override
  String hours(int hours) => 'منذ $hoursس';

  @override
  String aDay(int hours) => 'منذ 1ي';
  @override
  String days(int days) => 'منذ $daysي';

  @override
  String aboutAMonth(int days) => 'منذ 1ش';
  @override
  String months(int months) => 'منذ $monthsش';

  @override
  String aboutAYear(int year) => 'منذ 1سنة';
  @override
  String years(int years) => 'منذ $yearsسنوات';

  @override
  String wordSeparator() => ' ';
}
