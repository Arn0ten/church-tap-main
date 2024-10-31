import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = 'YOUR_API_KEY'; // Use your actual API key
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<String> getWeather(double lat, double lon) async {
    final response = await http.get(Uri.parse('$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String weatherDescription = data['weather'][0]['description'];
      return weatherDescription; // e.g., "clear sky"
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
