class Weather {
  final DateTime dateTime;
  final int weatherCode;
  final double temp_max;
  final double temp_min;
  final int rain_probability;
  final double wind_speed;

  Weather(
      {required this.dateTime,
      required this.weatherCode,
      required this.temp_max,
      required this.temp_min,
      required this.rain_probability,
      required this.wind_speed});

  factory Weather.fromJSON(Map<String, dynamic> map) {
    return Weather(
        dateTime: map['daily']['time'],
        weatherCode: map['daily']['weather_code'],
        temp_max: map['daily']['apparent_temperature_max'],
        temp_min: map['daily']['apparent_temperature_min'],
        rain_probability: map['daily']['precipitation_probability_max'],
        wind_speed: map['daily']['wind_speed_10m_max']);
  }
}
