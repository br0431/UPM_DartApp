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
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates(); // Corrected
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(), // Corrected
        c['latitude'].toString(), // Corrected
        c['longitude'].toString() // Corrected
      ]).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen'),
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
              title: Text('DB Timestamp: ${coord[0]}', style: TextStyle(color: Colors.blue)),
              subtitle: Text('Latitude: ${coord[1]}, Longitude: ${coord[2]}', style: TextStyle(color: Colors.blue)),
              onTap: () => showDeleteDialog(coord[0]), // Passing timestamp to the delete dialog
            );

          }
        },
      ),
    );
  }
}
