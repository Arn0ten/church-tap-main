import 'package:bethel_app_final/BACK_END/models/Weather.dart';

class DataParsing {
  final dynamic time;
  final dynamic weatherCode;
  final dynamic temp_max;
  final dynamic temp_min;
  final dynamic rain_probability;
  final dynamic wind_speed;

  DataParsing(
      {required this.time,
      required this.weatherCode,
      required this.temp_max,
      required this.temp_min,
      required this.rain_probability,
      required this.wind_speed});

  Weather convertToWeather() {
    return Weather(
        dateTime: getDateTime(),
        weatherCode: getWeatherCode(),
        temp_max: getMaxTemperature(),
        temp_min: getMinTemperature(),
        rain_probability: getRainProbability(),
        wind_speed: getMaxWindSpeed());
  }

  DateTime getDateTime() {
    return DateTime.parse(time);
  }

  int getWeatherCode() {
    return int.parse(weatherCode.toString());
  }

  double getMaxTemperature() {
    return double.parse(temp_max.toString());
  }

  double getMinTemperature() {
    return double.parse(temp_max.toString());
  }

  double getMaxWindSpeed() {
    return double.parse(wind_speed.toString());
  }

  int getRainProbability() {
    return int.parse(rain_probability.toString());
  }
}
