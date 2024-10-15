import 'package:flutter/material.dart';

import 'screens/admin_page.dart';
import 'screens/facility_inspection_screen.dart';
import 'screens/login_screen.dart';

void main() => runApp(const SpakleanApp());

class SpakleanApp extends StatelessWidget {
  const SpakleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spaklean',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Light blue as the theme color
      ),
      initialRoute: '/login', // Start with the login screen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/facilityInspection') {
          final args =
              settings.arguments as Map<String, dynamic>?; // Fetch arguments
          if (args != null &&
              args.containsKey('userId') &&
              args.containsKey('officeId')) {
            final userId = args['userId'];
            final officeId =
                args['officeId']; // Ensure officeId is passed as well
            return MaterialPageRoute(
              builder: (context) =>
                  FacilityInspectionScreen(userId: userId, officeId: officeId),
            );
          }
        }
        return null; // Return null if no matching route is found
      },
    );
  }
}
