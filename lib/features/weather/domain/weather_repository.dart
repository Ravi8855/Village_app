import 'daily_forecast.dart';

abstract class WeatherRepository {
  Future<List<DailyForecast>> fetchDaily({required double latitude, required double longitude});
}
