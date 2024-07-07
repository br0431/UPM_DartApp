import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '/db/database_helper.dart';
import 'weather_screen.dart';
import 'overpass_service.dart';

class OSMPlace {
  final String name;
  final String type;
  final LatLng location;

  OSMPlace({required this.name, required this.type, required this.location});
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<Marker> greenMarker = [];
  List<LatLng> routeCoordinates = [];
  List<Map<String, dynamic>> markerData = [];
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
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onSecondaryTap: () => removeMarker(LatLng(record['latitude'], record['longitude'])),
              child: Icon(
                Icons.location_pin,
                size: 60,
                color: Colors.red,
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  record['name'] ?? '',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
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
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onSecondaryTap: () => removeMarker(point),
                  child: Icon(
                    _getIconForType(coordMap['type']),
                    size: 60,
                    color: _getColorForType(coordMap['type']),
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      coordMap['name'] ?? '',
                      style: TextStyle(color: _getColorForType(coordMap['type'])),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        markerData.add({'point': point, 'name': coordMap['name'], 'type': coordMap['type']});
      }
    }

    setState(() {
      markers = loadedMarkers;
    });
  }

  void saveMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> markerList = markerData.map((data) =>
        jsonEncode({'lat': data['point'].latitude, 'lng': data['point'].longitude, 'name': data['name'], 'type': data['type']})).toList();
    await prefs.setStringList('markers', markerList);
  }

  void addMarker(LatLng point) async {
    String? markerName = await _showMarkerNameDialog();

    if (markerName == null || markerName.isEmpty) {
      return;
    }

    setState(() {
      markers.add(
        Marker(
          point: point,
          width: 80,
          height: 80,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onSecondaryTap: () => removeMarker(point),
                child: Icon(
                  Icons.location_pin,
                  size: 60,
                  color: Colors.greenAccent,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    markerName,
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      markerData.add({'point': point, 'name': markerName, 'type': 'custom'});
      saveMarkers();
    });
  }

  Future<String?> _showMarkerNameDialog() async {
    TextEditingController _nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Marker Name'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: 'Marker Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(_nameController.text);
              },
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'soccer':
        return Icons.sports_soccer;
      case 'tennis':
        return Icons.sports_tennis;
      case 'basketball':
        return Icons.sports_basketball;
      case 'swimming':
        return Icons.pool;
      case 'sports_centre':
        return Icons.accessibility_new;
      default:
        return Icons.location_on;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
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
      case 'custom':
        return Colors.blue; // Color for custom markers
      default:
        return Colors.indigo;
    }
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
              // Navigate to WeatherScreen
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
        MarkerLayer(markers: markers + greenMarker),
      ],
    );
  }

  TileLayer openStreetMapTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
  }

  void createRoute() {
    setState(() {
      // Filtramos los marcadores azules
      List<Marker> blueMarkers = markers.where((marker) {
        if (marker.builder != null) {
          Widget? markerWidget = marker.builder!(context);
          if (markerWidget is Column) {
            for (var child in markerWidget.children) {
              if (child is GestureDetector && child.child is Icon) {
                Icon icon = child.child as Icon;
                return icon.color == Colors.greenAccent;
              }
            }
          }
        }
        return false;
      }).toList();

      // Actualizamos la ruta solo si hay al menos dos marcadores azules
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
      markerData.removeWhere((data) => data['point'] == point);
      saveMarkers();
    });
  }

  void removeAllMarkers() {
    setState(() {
      markers.clear();
      markerData.clear();
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
      greenMarker.addAll(sportsFacilities.map((place) {
        return Marker(
          point: place.location,
          width: 80,
          height: 80,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForType(place.type),
                size: 60,
                color: _getColorForType(place.type),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    place.name,
                    style: TextStyle(color: _getColorForType(place.type)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList());
    });
  }
}
