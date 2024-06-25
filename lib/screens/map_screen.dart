// /lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/db/database_helper.dart';
import 'weather_screen.dart';
import 'overpass_service.dart';



class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<LatLng> routeCoordinates = [];
  List<LatLng> markerCoordinates = [];
  final OverpassService overpassService = OverpassService();

  @override
  void initState() {
    super.initState();
    loadMarkers();
    loadRouteCoordinates();
  }

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

  Future<void> searchSportsFacilities() async {
    final sportsFacilities = await overpassService.getSportsFacilities(
      40.40886242536441, // Centra la búsqueda en el centro del mapa
      -3.5250663094863905,
      5000, // Radio en metros
    );

    setState(() {
      markers.addAll(sportsFacilities.map((place) {
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
            onPressed: searchSportsFacilities, // Llama a la función de búsqueda
            color: Colors.deepOrange,
          ),
        ],
      ),
      body: content(),
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
