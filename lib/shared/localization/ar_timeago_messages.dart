import 'package:timeago/timeago.dart' as timeago;

/// Custom Arabic lookup messages for the timeago package.
class ArTimeagoMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => 'منذ';
  @override
  String prefixFromNow() => 'بعد';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';

  @override
  String lessThanOneMinute(int seconds) => 'لحظات';
  @override
  String aboutAMinute(int minutes) => 'دقيقة واحدة';
  @override
  String minutes(int minutes) {
    if (minutes == 1) return 'دقيقة واحدة';
    if (minutes == 2) return 'دقيقتين';
    if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
    return '$minutes دقيقة';
  }

  @override
  String aboutAnHour(int minutes) => 'ساعة واحدة';
  @override
  String hours(int hours) {
    if (hours == 1) return 'ساعة واحدة';
    if (hours == 2) return 'ساعتين';
    if (hours >= 3 && hours <= 10) return '$hours ساعات';
    return '$hours ساعة';
  }

  @override
  String aDay(int hours) => 'يوم واحد';
  @override
  String days(int days) {
    if (days == 1) return 'يوم واحد';
    if (days == 2) return 'يومين';
    if (days >= 3 && days <= 10) return '$days أيام';
    return '$days يومًا';
  }

  @override
  String aboutAMonth(int days) => 'شهر واحد';
  @override
  String months(int months) {
    if (months == 1) return 'شهر واحد';
    if (months == 2) return 'شهرين';
    if (months >= 3 && months <= 10) return '$months أشهر';
    return '$months شهرًا';
  }

  @override
  String aboutAYear(int year) => 'سنة واحدة';
  @override
  String years(int years) {
    if (years == 1) return 'سنة واحدة';
    if (years == 2) return 'سنتين';
    if (years >= 3 && years <= 10) return '$years سنوات';
    return '$years سنة';
  }

  @override
  String wordSeparator() => ' ';
}
