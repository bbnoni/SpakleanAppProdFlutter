// lib/screens/scoreboard_screen.dart
import 'package:flutter/material.dart';

class ScoreboardScreen extends StatelessWidget {
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
              Navigator.pushNamed(context, '/facilityInspection');
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
