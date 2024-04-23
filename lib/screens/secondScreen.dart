import 'package:flutter/material.dart';
import 'package:rv_ad_dart/main.dart';
import 'package:rv_ad_dart/screens/thirdScreen.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
      ),
      body: Center(
        child: Text('Welcome to the Map!'),
      ),
    );
  }

}