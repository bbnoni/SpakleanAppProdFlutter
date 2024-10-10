// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/admin_page.dart';
import 'screens/facility_inspection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/office_screen.dart';
import 'screens/scoreboard_screen.dart';

void main() => runApp(SpakleanApp());

class SpakleanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spaklean',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Light blue as the theme color
      ),
      initialRoute: '/login', // Start with the login screen
      routes: {
        '/login': (context) => LoginScreen(),
        '/office': (context) => OfficeScreen(),
        '/scoreboard': (context) => ScoreboardScreen(),
        '/facilityInspection': (context) => FacilityInspectionScreen(),
        '/admin': (context) => AdminPage(),
      },
    );
  }
}
