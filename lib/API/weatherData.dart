import 'dart:convert';

import 'package:http/http.dart' as http;

import '../BACK_END/models/DataParsing.dart';
import '../BACK_END/models/Weather.dart';

class DataApi {
  var today = DateTime.now();
  Future<List<Weather>> getApiData() async {
    List<Weather> wat = [];
    final response = await http.get(Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=7.4475&longitude=125.8046&daily=weather_code,apparent_temperature_max,apparent_temperature_min,precipitation_probability_max,wind_speed_10m_max&precipitation_unit=inch&timezone=Asia%2FSingapore&forecast_days=16'));
    final decode = jsonDecode(response.body);
    Map<String, List<dynamic>> dailyData =
        Map<String, List<dynamic>>.from(decode['daily']);

    for (int i = 0; i < dailyData['time']!.length; i++) {
      DataParsing parse = DataParsing(
          time: dailyData['time']![i],
          weatherCode: dailyData['weather_code']![i],
          temp_max: dailyData['apparent_temperature_max']![i],
          temp_min: dailyData['apparent_temperature_min']![i],
          rain_probability: dailyData['precipitation_probability_max']![i],
          wind_speed: dailyData['wind_speed_10m_max']![i]);
      wat.add(parse.convertToWeather());
    }
    return wat;
  }
}
