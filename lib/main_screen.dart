import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rv_ad_mad/screens/tablondeanuncios.dart';

import 'screens/splash_screen.dart';
import 'screens/second_screen.dart';
import 'screens/third_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/favoritosScreen.dart'; // Importar la pantalla de favoritos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MAD helloworldft',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data != null) {
              return MainScreen(); // Usuario está logueado
            }
            return LoginScreen(); // Usuario no está logueado
          }
          return const CircularProgressIndicator(); // Esperando conexión
        },
      ),
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2;
  final List<Widget> _screens = [
    SecondScreen(),
    MapScreen(),
    SplashScreen(),
    TablonDeAnunciosScreen(anuncios: [],),
    FavoritosScreen(), // Agregar la pantalla de favoritos aquí
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_filled_outlined),
            label: 'Advertisments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star), // Cambiar de Icons.favorite a Icons.star
            label: 'Favorites',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
