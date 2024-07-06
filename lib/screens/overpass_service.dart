import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSMPlace {
  final String name;
  final String type;
  final LatLng location;

  OSMPlace({required this.name, required this.type, required this.location});
}

class OverpassService {
  Future<List<OSMPlace>> getSportsFacilities(double lat, double lng, double radius) async {
    final overpassUrl = 'https://overpass-api.de/api/interpreter';
    final query = '''
    [out:json];
    (
      node["leisure"="sports_centre"](around:$radius,$lat,$lng);
      node["sport"="soccer"](around:$radius,$lat,$lng);
      node["sport"="tennis"](around:$radius,$lat,$lng);
      node["sport"="basketball"](around:$radius,$lat,$lng);
      node["sport"="swimming"](around:$radius,$lat,$lng);
    );
    out body;
    ''';

    final response = await http.post(Uri.parse(overpassUrl), body: {'data': query});

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final elements = jsonResponse['elements'] as List;

      return elements.map((element) {
        String type = element['tags']['sport'] ?? element['tags']['leisure'] ?? 'unknown';
        String name = element['tags']['name'] ?? 'Unnamed';
        LatLng location = LatLng(element['lat'], element['lon']);

        return OSMPlace(
          name: name,
          type: type,
          location: location,
        );
      }).toList();
    } else {
      throw Exception('Failed to load places from Overpass API');
    }
  }
}
