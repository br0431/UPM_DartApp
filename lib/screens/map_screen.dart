import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/db/database_helper.dart';
import 'weather_screen.dart'; // Importa la pantalla de WeatherScreen

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<LatLng> routeCoordinates = [];
  List<LatLng> markerCoordinates = [];

  @override
  void initState() {
    super.initState();
    loadMarkers();
    loadRouteCoordinates();
  }

  // Function to load list of markers from database
  Future<void> loadMarkers() async {
    final dbMarkers = await DatabaseHelper.instance.getCoordinates();

    List<Marker> loadedMarkers = dbMarkers.map((record) {
      return Marker(
        point: LatLng(record['latitude'], record['longitude']),
        width: 80,
        height: 80,
        builder: (ctx) => Icon(
          Icons.location_pin,
          size: 60,
          color: Colors.red,
        ),
      );
    }).toList();

    setState(() {
      markers = loadedMarkers;
    });
  }

  void loadRouteCoordinates() {
    // Load list of coordinates in the route
    routeCoordinates = [
      LatLng(40.407621980242745, -3.517071770311644),
      LatLng(40.409566291824795, -3.516234921159887),
      LatLng(40.41031785940011, -3.5146041381974897),
      LatLng(40.412784902661286, -3.513574170010713),
      LatLng(40.414189933233956, -3.512866066882304),
      LatLng(40.41686921259544, -3.511127995489052),
      LatLng(40.41997312229808, -3.5090251437743816),
    ];
  }

  void addMarker(LatLng point) {
    setState(() {
      markers.add(
        Marker(
          point: point,
          width: 80,
          height: 80,
          builder: (ctx) => Icon(
            Icons.location_pin,
            size: 60,
            color: Colors.blue,
          ),
        ),
      );
      markerCoordinates.add(point); // Agregar coordenadas del marcador
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Map View',
          style: TextStyle(color: Colors.deepOrange), // Cambia el color del texto a naranja
        ),
        centerTitle: true, // Centra el texto en la AppBar
        backgroundColor: Colors.black, // Cambia el color de fondo del AppBar a negro
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
            color: Colors.deepOrange, // Cambia el color del icono de nube a deepOrange
          ),
        ],
      ),
      body: content(),
    );
  }

  Widget content() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(40.40886242536441, -3.5250663094863905), // Focus
        zoom: 15,
        interactiveFlags: InteractiveFlag.all,
        onTap: (point, latlng) {
          addMarker(latlng); // Añadir marcador en la posición del puntero
        },
      ),
      children: [
        openStreetMapTileLayer(),
        MarkerLayer(markers: markers), // Loaded markers
        PolylineLayer(
          polylines: [
            Polyline(
              points: routeCoordinates,
              color: Colors.pink,
              strokeWidth: 8.0,
            ),
          ],
        ),
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
