import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spaklean_app/screens/office_screen.dart';

import 'screens/admin_page.dart';
import 'screens/ceo_dashboard_screen.dart';
import 'screens/facility_inspection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_selection_screen.dart'; // Import UserSelectionScreen

void main() => runApp(const SpakleanApp());

class SpakleanApp extends StatelessWidget {
  const SpakleanApp({super.key});

  // Determine the start screen based on user role and login status
  Future<Widget> _determineStartScreen() async {
    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'access_token');
    final userId = await storage.read(key: 'currentUserId');
    final role = await storage.read(key: 'role');

    if (accessToken != null && userId != null && role != null) {
      if (role == 'Custodian') {
        return OfficeScreen(userId: userId);
      } else if (role == 'Custodial Manager' || role == 'Facility Executive') {
        return UserSelectionScreen(role: role, userId: userId);
      } else if (role == 'Admin') {
        return const AdminPage();
      } else if (role == 'CEO') {
        return const CEODashboardScreen();
      }
    }
    return const LoginScreen(); // Default to login screen if not logged in
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a splash screen or loading indicator while determining start screen
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          title: 'Spaklean',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: snapshot.data, // Set the initial screen based on login status
          routes: {
            '/login': (context) => const LoginScreen(),
            '/admin': (context) => const AdminPage(),
            '/ceo': (context) => const CEODashboardScreen(),
            '/office': (context) {
              // Read the userId from arguments and navigate to OfficeScreen with it
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
              final userId = args?['userId'];
              return OfficeScreen(userId: userId);
            },
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/facilityInspection') {
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null &&
                  args.containsKey('userId') &&
                  args.containsKey('officeId')) {
                final userId = args['userId'];
                final officeId = args['officeId'];
                return MaterialPageRoute(
                  builder: (context) => FacilityInspectionScreen(
                    userId: userId,
                    officeId: officeId,
                  ),
                );
              }
            }
            return null; // Return null if no matching route is found
          },
        );
      },
    );
  }
}
