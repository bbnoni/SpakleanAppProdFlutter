import 'package:flutter/material.dart';

import 'custodian_attendance_screen.dart'; // Import Custodian Attendance screen
import 'facility_inspection_screen.dart';
import 'notification_screen.dart'; // Import Notification screen

class ScoreboardScreen extends StatelessWidget {
  final String userId; // Added userId parameter
  final String officeId; // Add officeId parameter

  // Constructor to accept userId and officeId
  const ScoreboardScreen(
      {super.key, required this.userId, required this.officeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoreboard - Spaklean'),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            Colors.blueAccent, // A consistent color for the app bar
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(16.0), // Adjust padding for a cleaner layout
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0, // Consistent horizontal spacing
          mainAxisSpacing: 16.0, // Consistent vertical spacing
          children: <Widget>[
            _buildGridTile(
              context,
              'Facility Inspection',
              Icons.cleaning_services,
              Colors.blue,
              FacilityInspectionScreen(
                userId: userId, // Pass userId to FacilityInspectionScreen
                officeId: officeId, // Pass officeId to FacilityInspectionScreen
              ),
            ),
            _buildGridTile(
              context,
              'Task Compliance',
              Icons.task_alt,
              Colors.green,
              null, // Feature not implemented yet
            ),
            _buildGridTile(
              context,
              'Tools & Equipment Audit (TEA)',
              Icons.build,
              Colors.orange,
              null, // Feature not implemented yet
            ),
            _buildGridTile(
              context,
              'Safety Records',
              Icons.security,
              Colors.red,
              null, // Feature not implemented yet
            ),
            _buildGridTile(
              context,
              'Custodian Records',
              Icons.person,
              Colors.purple,
              CustodianAttendanceScreen(
                userId: userId, // Pass userId to Custodian Attendance Screen
                officeId:
                    officeId, // Pass officeId to Custodian Attendance Screen
              ),
            ),
            _buildGridTile(
              context,
              'Cleaning Times',
              Icons.timer,
              Colors.cyan,
              null, // Feature not implemented yet
            ),
            _buildGridTile(
              context,
              'Notification',
              Icons.notifications,
              Colors.amber,
              NotificationScreen(
                userId: userId, // Pass userId to NotificationScreen
              ),
            ),
            _buildGridTile(
              context,
              'Setup',
              Icons.settings,
              Colors.grey,
              null, // Feature not implemented yet
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a grid tile with the necessary parameters
  Widget _buildGridTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget? nextPage,
  ) {
    return GestureDetector(
      onTap: () {
        if (nextPage != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextPage),
          );
        } else {
          _showFeatureUnavailableDialog(context, title);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.0), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Changes position of shadow
            ),
          ],
        ),
        padding: const EdgeInsets.all(8.0), // Consistent padding inside tiles
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display a dialog when the feature is unavailable
  void _showFeatureUnavailableDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$title Unavailable'),
          content: const Text('This feature is not available yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
