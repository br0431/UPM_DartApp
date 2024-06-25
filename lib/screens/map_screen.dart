import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '/db/database_helper.dart';
import 'weather_screen.dart';
import 'overpass_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<Marker> greenMarkers = [];
  List<LatLng> routeCoordinates = [];
  List<LatLng> markerCoordinates = [];
  final OverpassService overpassService = OverpassService();

  @override
  void initState() {
    super.initState();
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    final dbMarkers = await DatabaseHelper.instance.getCoordinates();

    List<Marker> loadedMarkers = dbMarkers.map((record) {
      return Marker(
        point: LatLng(record['latitude'], record['longitude']),
        width: 80,
        height: 80,
        builder: (ctx) => GestureDetector(
          onSecondaryTap: () => removeMarker(LatLng(record['latitude'], record['longitude'])),
          child: Icon(
            Icons.location_pin,
            size: 60,
            color: Colors.red,
          ),
        ),
      );
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    List<String>? savedMarkers = prefs.getStringList('markers');
    if (savedMarkers != null) {
      for (String marker in savedMarkers) {
        Map<String, dynamic> coordMap = jsonDecode(marker);
        LatLng point = LatLng(coordMap['lat'], coordMap['lng']);
        loadedMarkers.add(
          Marker(
            point: point,
            width: 80,
            height: 80,
            builder: (ctx) => GestureDetector(
              onSecondaryTap: () => removeMarker(point),
              child: Icon(
                Icons.location_pin,
                size: 60,
                color: Colors.blue,
              ),
            ),
          ),
        );
        markerCoordinates.add(point);
      }
    }

    setState(() {
      markers = loadedMarkers;
    });
  }

  void saveMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> markerList = markerCoordinates.map((coord) =>
        jsonEncode({'lat': coord.latitude, 'lng': coord.longitude})).toList();
    await prefs.setStringList('markers', markerList);
  }

  void addMarker(LatLng point) {
    setState(() {
      markers.add(
        Marker(
          point: point,
          width: 80,
          height: 80,
          builder: (ctx) => GestureDetector(
            onSecondaryTap: () => removeMarker(point),
            child: Icon(
              Icons.location_pin,
              size: 60,
              color: Colors.blue,
            ),
          ),
        ),
      );
      markerCoordinates.add(point);
      saveMarkers();
    });
  }

  void createRoute() {
    setState(() {
      List<Marker> blueMarkers = markers.where((marker) {
        if (marker.builder != null) {
          Widget? markerWidget = marker.builder!(context);
          return markerWidget is Icon && markerWidget.color == Colors.blue && markerWidget.icon == Icons.location_pin;
        }
        return false;
      }).toList();

      if (blueMarkers.length >= 2) {
        routeCoordinates = calculateRouteCoordinates(blueMarkers);
      } else {
        routeCoordinates.clear();
      }
      print("Route coordinates updated: $routeCoordinates");
    });
  }

  List<LatLng> calculateRouteCoordinates(List<Marker> blueMarkers) {
    blueMarkers.sort((a, b) => a.point.latitude.compareTo(b.point.latitude));

    List<LatLng> coords = [];
    for (int i = 0; i < blueMarkers.length - 1; i++) {
      LatLng start = blueMarkers[i].point;
      LatLng end = blueMarkers[i + 1].point;
      coords.add(start);
      coords.add(end);
    }
    return coords;
  }

  void removeMarker(LatLng point) {
    setState(() {
      markers.removeWhere((marker) => marker.point == point);
      markerCoordinates.removeWhere((coord) => coord == point);
      saveMarkers();
    });
  }

  void removeAllMarkers() {
    setState(() {
      markers.clear();
      markerCoordinates.clear();
      routeCoordinates.clear();
      saveMarkers();
    });
  }

  Future<void> searchSportsFacilities() async {
    final sportsFacilities = await overpassService.getSportsFacilities(
      40.40886242536441, // Centra la búsqueda en el centro del mapa
      -3.5250663094863905,
      50000, // Radio en metros
    );

    setState(() {
      greenMarkers.addAll(sportsFacilities.map((place) {
        return Marker(
          point: place.location,
          width: 80,
          height: 80,
          builder: (ctx) => Icon(
            Icons.sports_soccer, // Ícono predeterminado para polideportivos/campos de fútbol
            size: 60,
            color: Colors.green,
          ),
        );
      }).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Map View',
          style: TextStyle(color: Colors.deepOrange),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.cloud),
            onPressed: () {
              // Navegar a WeatherScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeatherScreen(
                    latitude: 40.0,
                    longitude: -3.0,
                    routeCoordinates: routeCoordinates,
                  ),
                ),
              );
            },
            color: Colors.deepOrange,
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: searchSportsFacilities,
            color: Colors.deepOrange,
          ),
        ],
      ),
      body: content(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: removeAllMarkers,
            tooltip: 'Remove All Markers',
            backgroundColor: Colors.deepOrange,
            child: Icon(Icons.delete),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: createRoute,
            tooltip: 'Create Route',
            backgroundColor: Colors.blue,
            child: Icon(Icons.alt_route),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget content() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(40.40886242536441, -3.5250663094863905),
        zoom: 15,
        interactiveFlags: InteractiveFlag.all,
        onTap: (point, latlng) {
          addMarker(latlng);
        },
      ),
      children: [
        openStreetMapTileLayer(),
        PolylineLayer(
          polylines: [
            Polyline(
              points: routeCoordinates,
              color: Colors.red,
              strokeWidth: 3.0,
            ),
          ],
        ),
        MarkerLayer(markers: markers + greenMarkers),
      ],
    );
  }

  TileLayer openStreetMapTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
  }
}

