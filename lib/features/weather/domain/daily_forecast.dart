import 'package:equatable/equatable.dart';

class DailyForecast extends Equatable {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTempC,
    required this.minTempC,
    required this.rainChancePercent,
  });

  final DateTime date;
  final int weatherCode;
  final double maxTempC;
  final double minTempC;
  final int rainChancePercent;

  @override
  List<Object?> get props =>
      [date, weatherCode, maxTempC, minTempC, rainChancePercent];
}
