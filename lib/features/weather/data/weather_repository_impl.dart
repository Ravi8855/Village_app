import '../domain/daily_forecast.dart';
import '../domain/weather_repository.dart';
import 'open_meteo_remote_datasource.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._remote);

  final OpenMeteoRemoteDataSource _remote;

  @override
  Future<List<DailyForecast>> fetchDaily({
    required double latitude,
    required double longitude,
  }) {
    return _remote.fetchDaily(latitude: latitude, longitude: longitude);
  }
}
