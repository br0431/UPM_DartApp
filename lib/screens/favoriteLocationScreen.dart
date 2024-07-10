import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overpass_service.dart';
import 'FavoriteLocationsManager.dart';

class FavoriteLocationScreen extends StatelessWidget {
  final OSMPlace facility;

  FavoriteLocationScreen({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorite Centers',
          style: TextStyle(color: Colors.deepOrange), // Color deepOrange para el título
        ),
        centerTitle: true, // Centra el título en la AppBar
        backgroundColor: Colors.black, // Fondo negro para la AppBar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              facility.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForType(facility.type),
                  size: 30,
                  color: _getColorForType(facility.type),
                ),
                SizedBox(width: 10),
                Text(
                  facility.type,
                  style: TextStyle(
                    fontSize: 20,
                    color: _getColorForType(facility.type),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                saveFavoriteLocation(facility);
                Navigator.of(context).pop();
              },
              child: Text(
                'Guardar como favorito',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void saveFavoriteLocation(OSMPlace facility) {
    FavoriteLocationsManager.addFavorite(facility);
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'soccer':
        return Icons.sports_soccer;
      case 'tennis':
        return Icons.sports_tennis;
      case 'basketball':
        return Icons.sports_basketball;
      case 'swimming':
        return Icons.pool;
      case 'sports_centre':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'soccer':
        return Colors.green;
      case 'tennis':
        return Colors.orange;
      case 'basketball':
        return Colors.blue;
      case 'swimming':
        return Colors.blueAccent;
      case 'sports_centre':
        return Colors.red;
      default:
        return Colors.indigo;
    }
  }
}
