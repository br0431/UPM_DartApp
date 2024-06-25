import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSMPlace {
  final String name;
  final LatLng location;

  OSMPlace({required this.name, required this.location});
}

class OverpassService {
  Future<List<OSMPlace>> getSportsFacilities(double lat, double lng, double radius) async {
    final overpassUrl = 'https://overpass-api.de/api/interpreter';
    final query = '''
    [out:json];
    (
      node["leisure"="sports_centre"](around:$radius,$lat,$lng);
      node["sport"="soccer"](around:$radius,$lat,$lng);
    );
    out body;
    ''';

    final response = await http.post(Uri.parse(overpassUrl), body: {'data': query});

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final elements = jsonResponse['elements'] as List;

      return elements.map((element) {
        return OSMPlace(
          name: element['tags']['name'] ?? 'Unnamed',
          location: LatLng(element['lat'], element['lon']),
        );
      }).toList();
    } else {
      throw Exception('Failed to load places from Overpass API');
    }
  }
}
