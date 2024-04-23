import 'package:flutter/material.dart';
import 'package:rv_ad_dart/main.dart';
import 'package:rv_ad_dart/screens/secondScreen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: kToolbarHeight + 35, // Altura de la AppBar emulada
            decoration: BoxDecoration(
              color: Colors.orange, // Color de la AppBar emulada
            ),
            child: Center(
              child: Text(
                'Flutter MAD Rodrigo & Alexandru',
                style: TextStyle(
                  color: Colors.black, // Color del texto de la AppBar emulada
                  fontSize: 20, // Tamaño del texto de la AppBar emulada
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }








}