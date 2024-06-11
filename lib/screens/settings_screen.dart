import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rv_ad_mad/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, TextEditingController> controllers = {};

  Future<Map<String, dynamic>> _fetchAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> prefsMap = {};
    for (String key in keys) {
      prefsMap[key] = prefs.get(key);
      controllers[key] = TextEditingController(text: prefs.get(key).toString());
    }
    return prefsMap;
  }

  Future<void> _updatePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "Settings",
          style: TextStyle(color: Colors.deepOrange),
        ),
        iconTheme: IconThemeData(color: Colors.deepOrange),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAllPreferences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            return Stack(
              children: [
                ListView(
                  children: snapshot.data!.entries.map((entry) {
                    return ListTile(
                      title: Text("${entry.key}"),
                      subtitle: TextField(
                        controller: controllers[entry.key],
                        decoration: InputDecoration(hintText: "Enter ${entry.key}"),
                        onSubmitted: (value) {
                          _updatePreference(entry.key, value);
                        },
                      ),
                    );
                  }).toList(),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Próximamente!!',
                        style: TextStyle(color: Colors.white60, fontSize: 24),
                      ),
                      SizedBox(height: 10), // Espacio entre el texto y el icono
                      Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 36,
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showLogoutConfirmationDialog();
        },
        child: Icon(Icons.logout),
        backgroundColor: Colors.deepOrange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }
}
