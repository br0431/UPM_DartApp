import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:rv_ad_mad/db/database_helper.dart';
import 'dart:io';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  List<List<String>> _coordinates = [];
  List<List<String>> _dbCoordinates = []; // For coordinates from the database

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
    _loadDbCoordinates();
  }

  Future<void> _loadCoordinates() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    List<String> lines = await file.readAsLines();
    setState(() {
      _coordinates = lines.map((line) => line.split(';')).toList();
    });
  }

  Future<void> _loadDbCoordinates() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates();
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(),
        c['latitude'].toString(),
        c['longitude'].toString()
      ]).toList();
    });
  }

  void _loadDbCoordinatesAndUpdate() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates();
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(),
        c['latitude'].toString(),
        c['longitude'].toString()
      ]).toList();
    });
  }

  void _showUpdateDialog(String timestamp, String currentLat, String currentLong) {
    TextEditingController latController = TextEditingController(text: currentLat);
    TextEditingController longController = TextEditingController(text: currentLong);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update coordinates for $timestamp"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: latController,
                decoration: InputDecoration(labelText: "Latitude"),
              ),
              TextField(
                controller: longController,
                decoration: InputDecoration(labelText: "Longitude"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Update"),
              onPressed: () async {
                Navigator.of(context).pop();
                await DatabaseHelper.instance.updateCoordinate(timestamp, latController.text, longController.text);
                _loadDbCoordinatesAndUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(String timestamp) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm delete $timestamp"),
          content: Text("Do you want to delete this coordinate?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await DatabaseHelper.instance.deleteCoordinate(timestamp);
                Navigator.of(context).pop(); // Dismiss the dialog
                _loadDbCoordinatesAndUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          'Coordiates',
          style: TextStyle(color: Colors.deepOrange),
        ),
        iconTheme: IconThemeData(color: Colors.white), // For the back button color
      ),
      body: ListView.builder(
        itemCount: _coordinates.length + _dbCoordinates.length, // Combined count
        itemBuilder: (context, index) {
          if (index < _coordinates.length) {
            var coord = _coordinates[index];
            return ListTile(
              title: Text('CSV Timestamp: ${coord[0]}'),
              subtitle: Text('Latitude: ${coord[1]}, Longitude: ${coord[2]}'),
            );
          } else {
            var dbIndex = index - _coordinates.length;
            var coord = _dbCoordinates[dbIndex];
            return ListTile(
              title: Text(
                'DB Timestamp: ${coord[0]}',
                style: TextStyle(color: Colors.blue),
              ),
              subtitle: Text(
                'Latitude: ${coord[1]}, Longitude: ${coord[2]}',
                style: TextStyle(color: Colors.blue),
              ),
              onTap: () => showDeleteDialog(coord[0]),
              onLongPress: () => _showUpdateDialog(coord[0], coord[1], coord[2]),
            );
          }
        },
      ),
    );
  }
}
