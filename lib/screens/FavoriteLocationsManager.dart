import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overpass_service.dart';



class FavoriteLocationsManager {
  static final List<OSMPlace> _favoriteLocations = [];

  static List<OSMPlace> get favoriteLocations => _favoriteLocations;

  static void addFavorite(OSMPlace location) {
    _favoriteLocations.add(location);
    saveToPreferences();
  }

  static void removeFavorite(OSMPlace location) {
    _favoriteLocations.remove(location);
    saveToPreferences();
  }

  static Future<void> loadFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteLocationsStrings = prefs.getStringList('favorite_locations');
    if (favoriteLocationsStrings != null) {
      _favoriteLocations.clear();
      _favoriteLocations.addAll(favoriteLocationsStrings.map((locationString) {
        Map<String, dynamic> locationMap = jsonDecode(locationString);
        return OSMPlace(
          name: locationMap['name'],
          type: locationMap['type'],
          location: LatLng(locationMap['lat'], locationMap['lng']),
        );
      }).toList());
    }
  }

  static Future<void> saveToPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteLocationsStrings = _favoriteLocations.map((location) {
      return jsonEncode({
        'name': location.name,
        'type': location.type,
        'lat': location.location.latitude,
        'lng': location.location.longitude,
      });
    }).toList();
    await prefs.setStringList('favorite_locations', favoriteLocationsStrings);
  }
}
