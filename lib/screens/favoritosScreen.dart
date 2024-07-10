import 'package:flutter/material.dart';
import 'FavoriteLocationsManager.dart';
import 'overpass_service.dart';

class FavoritosScreen extends StatefulWidget {
  @override
  _FavoritosScreenState createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true, // Centra el título en la AppBar
        title: Text(
          'Favorite centers',
          style: TextStyle(color: Colors.deepOrange),
        ),
      ),
      body: FavoriteLocationsManager.favoriteLocations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Favorite Centers',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            SizedBox(height: 8),
            Text(
              'No favorite centers added',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: FavoriteLocationsManager.favoriteLocations.length,
        itemBuilder: (context, index) {
          OSMPlace location = FavoriteLocationsManager.favoriteLocations[index];
          return _buildFavoriteLocationTile(location);
        },
      ),
    );
  }

  Widget _buildFavoriteLocationTile(OSMPlace location) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Fondo gris claro para cada ubicación favorita
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          _getIconForType(location.type),
          color: _getColorForType(location.type),
        ),
        title: Text(
          location.name,
          style: TextStyle(color: Colors.deepOrange),
        ),
        subtitle: Text(location.type),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.deepOrange),
          onPressed: () {
            _deleteFavoriteLocation(location);
          },
        ),
        onTap: () {
          // Agrega aquí la lógica que desees al hacer tap en el ListTile
        },
      ),
    );
  }

  void _deleteFavoriteLocation(OSMPlace location) {
    FavoriteLocationsManager.removeFavorite(location);
    setState(() {});
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
