import '../../../core/constants/location_constants.dart';
import '../../../core/network/http_client.dart';
import '../domain/daily_forecast.dart';

class OpenMeteoRemoteDataSource {
  OpenMeteoRemoteDataSource(this._http);

  final HttpClient _http;

  Uri _uri(double latitude, double longitude) {
    return Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
      '&timezone=auto'
      '&forecast_days=7',
    );
  }

  Future<List<DailyForecast>> fetchDaily({
    double latitude = NaganoorLocation.latitude,
    double longitude = NaganoorLocation.longitude,
  }) async {
    final json = await _http.getJson(_uri(latitude, longitude));
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final times = (daily['time'] as List<dynamic>? ?? []).cast<String>();
    final codes =
        (daily['weather_code'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList();
    final maxTemps = (daily['temperature_2m_max'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final minTemps = (daily['temperature_2m_min'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final rain = (daily['precipitation_probability_max'] as List<dynamic>? ?? [])
        .map((e) => (e as num?)?.round() ?? 0)
        .toList();

    final list = <DailyForecast>[];
    for (var i = 0; i < times.length; i++) {
      list.add(
        DailyForecast(
          date: DateTime.parse(times[i]),
          weatherCode: i < codes.length ? codes[i] : 0,
          maxTempC: i < maxTemps.length ? maxTemps[i] : 0,
          minTempC: i < minTemps.length ? minTemps[i] : 0,
          rainChancePercent: i < rain.length ? rain[i] : 0,
        ),
      );
    }
    return list;
  }
}
