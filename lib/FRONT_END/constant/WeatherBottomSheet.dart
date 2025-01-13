import 'package:flutter/material.dart';

import '../../BACK_END/models/Weather.dart';
import '../MemberScreens/widget_member/widget/calendar/BoxContainer.dart';

class WeatherSheetTab extends StatefulWidget {
  final Weather weather;
  const WeatherSheetTab({super.key, required this.weather});

  @override
  State<WeatherSheetTab> createState() => _WeatherSheetTabState();
}

class _WeatherSheetTabState extends State<WeatherSheetTab> {
  @override
  Widget build(BuildContext context) {
    double weatherAvg = widget.weather.temp_max + widget.weather.temp_min / 2;
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35), topRight: Radius.circular(35))),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(50, 25, 50, 0),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tagum',
                style: defaultFont(30, FontWeight.bold),
              ),
              Text(
                'Chance of rain: ${widget.weather.rain_probability}%',
                style: defaultFont(15, FontWeight.normal),
              ),
              const SizedBox(
                height: 40,
              ),
              Image.asset(
                determineWeatherPicture(widget.weather.weatherCode),
                height: 150,
              ),
              const SizedBox(
                height: 40,
              ),
              FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(
                  determineWeather(widget.weather.weatherCode),
                  style: defaultFont(35, FontWeight.bold),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
              Boxcontainer(
                weather: widget.weather,
              )
            ],
          ),
        ],
      ),
    );
  }

  TextStyle defaultFont(double fontSize, FontWeight fontWeight) {
    return TextStyle(
        fontSize: fontSize, fontFamily: 'Arial', fontWeight: fontWeight);
  }

  String determineWeather(int weatherCodeNumber) {
    //Pwede rani sila sa json file pero kapoy naman mag himog async functions haha
    try {
      Map<int, String> weatherCodeMap = {
        0: 'Clear Sky',
        1: 'Mainly Clear',
        2: 'Partly Cloudy',
        3: 'Overcast',
        45: 'Fog',
        48: 'Depositing Rime Fog',
        51: 'Drizzle: Light',
        53: 'Drizzle: Moderate',
        55: 'Drizzle: Dense Intensity',
        56: 'Freezing Drizzle: Light',
        57: 'Freezing Drizzle: Dense',
        61: 'Rain: Slight',
        63: 'Rain: Moderate',
        65: 'Rain: Heavy',
        66: 'Freezing Rain: Light',
        67: 'Freezing Rain: Heavy',
        80: 'Rain showers: Slight',
        81: 'Rain showers: Moderate',
        82: 'Rain showers: Violent',
        95: 'Thunderstorm: Slight or Moderate',
        96: 'Thunderstorm: Slight'
      };
      return weatherCodeMap[weatherCodeNumber]!;
    } catch (e) {
      return 'Weather not found';
    }
  }

  String determineWeatherPicture(int weatherCodeNumber) {
    try {
      Map<int, String> weatherImage = {
        0: 'assets/images/calendar/sun.png',
        1: 'assets/images/calendar/sun.png',
        2: 'assets/images/calendar/clouds.png',
        3: 'assets/images/calendar/clouds.png',
        45: 'assets/images/calendar/404.jpg',
        48: 'assets/images/calendar/404.jpg',
        51: 'assets/images/calendar/drizzle.jpg',
        53: 'assets/images/calendar/drizzle.jpg',
        55: 'assets/images/calendar/drizzle.jpg',
        56: 'assets/images/calendar/drizzle.jpg',
        57: 'assets/images/calendar/drizzle.jpg',
        61: 'assets/images/calendar/rain.png',
        63: 'assets/images/calendar/rain.png',
        65: 'assets/images/calendar/rain.png',
        66: 'assets/images/calendar/rain.png',
        67: 'assets/images/calendar/rain.png',
        80: 'assets/images/calendar/rain.png',
        81: 'assets/images/calendar/rain.png',
        82: 'assets/images/calendar/rain.png',
        95: 'assets/images/calendar/thunderstorm.png',
        96: 'assets/images/calendar/thunderstorm.png'
      };
      return weatherImage[weatherCodeNumber]!;
    } catch (e) {
      return 'assets/images/calendar/404.jpg';
    }
  }
}
