import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map View')),
      body: content(),
    );
  }

  Widget content() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(40.38923590951672, -3.627749768768932),
        zoom: 15,
        interactiveFlags: InteractiveFlag.doubleTapZoom,
      ),
      children: [
        openStreetMapTileLayer(),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(40.38923590951672, -3.627749768768932),
              width: 80,
              height: 80,
              builder: (_) => Stack(
                children: [
                  Icon(
                    Icons.location_pin,
                    size: 60,
                    color: Colors.yellow,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white,
                      child: Text(
                        'You are here!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
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
