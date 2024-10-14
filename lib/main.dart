import 'package:flutter/material.dart';

import 'screens/admin_page.dart';
import 'screens/facility_inspection_screen.dart';
import 'screens/login_screen.dart';

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
        '/admin': (context) => AdminPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/facilityInspection') {
          final args =
              settings.arguments as Map<String, dynamic>?; // Fetch arguments
          if (args != null && args.containsKey('userId')) {
            final userId = args['userId'];
            return MaterialPageRoute(
              builder: (context) => FacilityInspectionScreen(userId: userId),
            );
          }
        }
        return null; // Return null if no matching route is found
      },
    );
  }
}
