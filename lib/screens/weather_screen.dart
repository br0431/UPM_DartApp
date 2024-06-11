import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WeatherScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<LatLng> routeCoordinates; // Añade el parámetro routeCoordinates

  WeatherScreen({required this.latitude, required this.longitude, required this.routeCoordinates});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic> weatherData = {};

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?lat=${widget.latitude}&lon=${widget.longitude}&appid=86b930582d32c6d7262549a6fd3ff28f'),
      );

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (weatherData.isNotEmpty &&
        weatherData['list'] != null &&
        weatherData['list'].isNotEmpty) {
      String iconCode = weatherData['list'][0]['weather'][0]['icon'];
      String iconUrl = 'http://openweathermap.org/img/wn/$iconCode.png';

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Weather Information',
            style: TextStyle(color: Colors.deepOrange),
          ),
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.deepOrange), // Cambiar color de la flecha de retroceso
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${weatherData['list'][0]['name']}',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Container(
                width: 200,
                height: 200,
                child: Image.network(
                  iconUrl,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Country: ${weatherData['list'][0]['sys']['country']}',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Coordinates: ${widget.latitude}, ${widget.longitude}',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Feels Like: ${(weatherData['list'][0]['main']['feels_like'] - 273.15).toStringAsFixed(1)}°C',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Description: ${weatherData['list'][0]['weather'][0]['description']}',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Temperature: ${(weatherData['list'][0]['main']['temp'] - 273.15).toStringAsFixed(1)}°C',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Humidity: ${weatherData['list'][0]['main']['humidity']}%',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Wind Speed: ${weatherData['list'][0]['wind']['speed']} m/s',
                style: TextStyle(fontSize: 18.0),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Weather Information',
            style: TextStyle(color: Colors.deepOrange),
          ),
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.deepOrange), // Cambiar color de la flecha de retroceso
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
