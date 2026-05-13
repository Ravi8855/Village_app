class WeatherCodeDescriptions {
  static String label(int code) {
    if (code == 0) return 'Clear skies';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy spells';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain showers';
    if (code <= 77) return 'Snow / hail risk';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    if (code <= 99) return 'Thunderstorms possible';
    return 'Mixed conditions';
  }
}
