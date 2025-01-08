import 'package:bethel_app_final/API/weatherData.dart';

import '../../../../BACK_END/models/Weather.dart';

class Controllers {
  List<Weather> weather = [];

  Controllers() {
    loadWeather();
  }

  Future<void> loadWeather() async {
    weather = await DataApi().getApiData();
  }

  List<Weather> getWeather() {
    return weather;
  }
}
