import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/location_constants.dart';
import '../../../core/di/core_providers.dart';
import '../data/open_meteo_remote_datasource.dart';
import '../data/weather_repository_impl.dart';
import '../domain/daily_forecast.dart';
import '../domain/weather_repository.dart';

final openMeteoDataSourceProvider = Provider<OpenMeteoRemoteDataSource>((ref) {
  return OpenMeteoRemoteDataSource(ref.watch(httpClientProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(ref.watch(openMeteoDataSourceProvider));
});

final weeklyForecastProvider =
    FutureProvider.autoDispose<List<DailyForecast>>((ref) async {
  final repo = ref.watch(weatherRepositoryProvider);
  return repo.fetchDaily(
    latitude: NaganoorLocation.latitude,
    longitude: NaganoorLocation.longitude,
  );
});
