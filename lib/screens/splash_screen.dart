import 'package:flutter/material.dart';
import 'package:rv_ad_mad/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'settings_screen.dart';
import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'third_screen.dart'; // Importa ThirdScreen aquí

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
        backgroundColor: Colors.black,
        centerTitle: true,
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
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.deepOrange), // Icono de campana
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ThirdScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Welcome to the Home Screen!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40), // Espacio entre el texto y el siguiente elemento
            Text(
              'Activar ubicación',
              style: TextStyle(color: Colors.deepOrange, fontSize: 18),
            ),
            SizedBox(height: 8),
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
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están desactivados.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Se denegaron los permisos de ubicación');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Los permisos de ubicación se denegaron permanentemente');
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
      mode: FileMode.append,
    );
  }
}
