import 'package:flutter/material.dart';

import '../../../../../BACK_END/models/Weather.dart';

class Boxcontainer extends StatelessWidget {
  final Weather weather;
  const Boxcontainer({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 200, //380 original
        width: 350,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 2, // Adjust based on how much grid items you want
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 15.0,
          ),
          itemBuilder: (context, index) => customContainer(index),
        ));
  }

  TextStyle titleFont() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
    );
  }

  TextStyle contentFont() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
    );
  }

  Widget customContainer(int index) {
    List<String> title = ['Temperature', 'Max Wind Speed'];
    Map<int, String> signs = {0: '°C', 1: ' km/h'};
    Map<String, dynamic> map = {
      'Temperature': (weather.temp_min + weather.temp_max) / 2,
      'Max Wind Speed': weather.wind_speed,
    };
    return Container(
      color: Colors.green.shade400,
      child: Column(
        children: [
          Text(title[index]),
          const SizedBox(
            height: 10,
          ),
          Text('${map[title[index]]}${signs[index]}')
        ],
      ),
    );
  }
}
