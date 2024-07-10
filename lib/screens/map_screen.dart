import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '/db/database_helper.dart';

import 'favoriteLocationScreen.dart';
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
            onPressed: () async {
              List<OSMPlace> facilities= await showSportsFacilitiesOnMap();

            },
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
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () async {
              List<OSMPlace> facilities = await getSportsFacilitiesList();
              showSportsFacilitiesScreen(facilities);
            },
            tooltip: 'Favorite Locations',
            backgroundColor: Colors.greenAccent,
            child: Icon(Icons.star),
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

  void createRoute() {
    setState(() {
      // Filtramos los marcadores verdes
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

      // Actualizamos la ruta solo si hay al menos dos marcadores verdes
      if (blueMarkers.length >= 2) {
        routeCoordinates = calculateRouteCoordinates(blueMarkers);
        print("Route coordinates updated: $routeCoordinates");
      } else {
        routeCoordinates.clear();
        _showMessageDialog(
            'Se necesitan al menos dos marcadores verdes para crear una ruta.');
      }
    });
  }

  List<LatLng> calculateRouteCoordinates(List<Marker> blueMarkers) {
    List<LatLng> coordinates = [];
    for (var marker in blueMarkers) {
      coordinates.add(marker.point);
    }
    return coordinates;
  }
  Future<List<OSMPlace>> showSportsFacilitiesOnMap() async {
    final sportsFacilities = await overpassService.getSportsFacilities(
      40.40886242536441, // Centra la búsqueda en el centro del mapa
      -3.5250663094863905,
      50000, // Radio en metros
    );

    // Caracter específico a filtrar
    String specificCharacter = 'Ã'; // Por ejemplo, el carácter '@'

    // Filtra los lugares que no tengan nombre "unnamed" y no contengan el carácter específico
    List<OSMPlace> filteredFacilities = sportsFacilities.where((facility) {
      return facility.name != null &&
          facility.name != "Unnamed" &&
          !facility.name!.contains(specificCharacter);
    }).toList();

    // Limpiar marcadores existentes
    setState(() {
      markers.clear();
      routeCoordinates.clear();
    });

    // Mostrar marcadores para las instalaciones deportivas encontradas
    List<Marker> facilityMarkers = filteredFacilities.map((facility) {
      return Marker(
        point: facility.location,
        width: 80,
        height: 80,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onSecondaryTap: () {
                // Mostrar opción para añadir a favoritos

              },
              child: Icon(
                _getIconForType(facility.type),
                size: 60,
                color: _getColorForType(facility.type),
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  facility.name ?? '',
                  style: TextStyle(color: _getColorForType(facility.type)),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    setState(() {
      markers.addAll(facilityMarkers);
    });

    return filteredFacilities;
  }

  Future<List<OSMPlace>> getSportsFacilitiesList() async {
    final sportsFacilities = await overpassService.getSportsFacilities(
      40.40886242536441, // Centra la búsqueda en el centro del mapa
      -3.5250663094863905,
      50000, // Radio en metros
    );

    // Caracter específico a filtrar
    String specificCharacter = 'Ã'; // Por ejemplo, el carácter '@'

    // Filtra los lugares que no tengan nombre "unnamed" y no contengan el carácter específico
    List<OSMPlace> filteredFacilities = sportsFacilities.where((facility) {
      return facility.name != null &&
          facility.name != "Unnamed" &&
          !facility.name!.contains(specificCharacter);
    }).toList();

    return filteredFacilities;
  }

  void showSportsFacilitiesScreen(List<OSMPlace> facilities) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SportsFacilitiesScreen(
          facilities: facilities,
          onFavoriteChanged: (OSMPlace facility, bool isFavorite) {
            // Actualizar el estado visual de la instalación deportiva marcada como favorita
            setState(() {
              int index = markers.indexWhere((marker) => marker.point == facility.location);
              if (index != -1) {
                Marker marker = markers[index];
                markers[index] = Marker(
                  point: marker.point,
                  width: marker.width,
                  height: marker.height,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onSecondaryTap: () {
                          // Mostrar opción para añadir a favoritos
                          addFavoriteLocation(facility);
                        },
                        child: Icon(
                          _getIconForType(facility.type),
                          size: 60,
                          color: _getColorForType(facility.type),
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            facility.name ?? '',
                            style: TextStyle(color: _getColorForType(facility.type)),
                          ),
                        ),
                      ),
                      Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                    ],
                  ),
                );
              }
            });
          },
        ),
      ),
    );
  }

  void addFavoriteLocation(OSMPlace facility) {
    // Guardar la ubicación favorita
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoriteLocationScreen(
          facility: facility,
        ),
      ),
    );
  }








  void removeAllMarkers() {
    setState(() {
      markers.clear();
      routeCoordinates.clear();
      saveMarkers();
    });
  }

  void removeMarker(LatLng point) {
    setState(() {
      markers.removeWhere((marker) => marker.point == point);
      greenMarkers.removeWhere((marker) => marker.point == point);
      routeCoordinates.remove(point);
      markerData.removeWhere((data) => data['point'] == point);
      saveMarkers();
    });
  }

  void _showMessageDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Message'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}


class SportsFacilitiesScreen extends StatefulWidget {
  final List<OSMPlace> facilities;
  final Function(OSMPlace, bool) onFavoriteChanged;

  SportsFacilitiesScreen({required this.facilities, required this.onFavoriteChanged});

  @override
  _SportsFacilitiesScreenState createState() => _SportsFacilitiesScreenState();
}

class _SportsFacilitiesScreenState extends State<SportsFacilitiesScreen> {
  List<bool> isFavoriteList = [];

  @override
  void initState() {
    super.initState();
    isFavoriteList = List.generate(widget.facilities.length, (index) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Instalaciones deportivas',
          style: TextStyle(color: Colors.deepOrange),
        ),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: widget.facilities.length,
        itemBuilder: (context, index) {
          OSMPlace facility = widget.facilities[index];
          bool isFavorite = isFavoriteList[index];

          return ListTile(
            title: Text(
              facility.name ?? 'Desconocido',
              style: TextStyle(color: Colors.deepOrange),
            ),
            subtitle: Text('${facility.type}'),
            trailing: GestureDetector(
              onTap: () {
                setState(() {
                  isFavorite = !isFavorite;
                  isFavoriteList[index] = isFavorite;
                  widget.onFavoriteChanged(facility, isFavorite);
                  if (isFavorite) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoriteLocationScreen(facility: facility),
                      ),
                    );
                  }
                });
              },
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}