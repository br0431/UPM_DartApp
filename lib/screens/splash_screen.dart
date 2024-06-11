import 'package:flutter/material.dart';
import 'package:rv_ad_mad/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'settings_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  DatabaseHelper db = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Fondo oscuro
        centerTitle: true, // Centrar el título
        title: Text('Home', style: TextStyle(color: Colors.deepOrange)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings, color: Colors.deepOrange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to the Home Screen!'),
            Switch(
              value: _positionStreamSubscription != null,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    startTracking();
                  } else {
                    stopTracking();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void startTracking() async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Adjust the accuracy as needed
      distanceFilter: 10, // Distance in meters before an update is triggered
    );
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
              (Position position) {
            writePositionToFile(position);
          },
        );
    // insert into sqflite db
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        db.insertCoordinate(position);
      },
    );

  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> writePositionToFile(Position position) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await file.writeAsString(
        '${timestamp};${position.latitude};${position.longitude}\n',
        mode: FileMode.append);
  }
}
