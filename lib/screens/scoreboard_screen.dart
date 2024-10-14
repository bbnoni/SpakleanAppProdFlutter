import 'package:flutter/material.dart';

class ScoreboardScreen extends StatelessWidget {
  final String userId; // Added userId parameter

  // Constructor to accept userId
  ScoreboardScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Spaklean Scoreboard"),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Facility Inspection'),
            onTap: () {
              // Pass userId when navigating to FacilityInspectionScreen
              Navigator.pushNamed(
                context,
                '/facilityInspection',
                arguments: {'userId': userId},
              );
            },
          ),
          ListTile(
            title: Text('Tools & Equipment Audit (TEA)'),
            onTap: () {
              // Future navigation to TEA screen
            },
          ),
          ListTile(
            title: Text('Safety Records'),
            onTap: () {
              // Future navigation to Safety Records screen
            },
          ),
          // Add more ListTiles for the other scoreboard items
        ],
      ),
    );
  }
}
