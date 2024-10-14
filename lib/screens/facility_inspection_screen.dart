import 'package:flutter/material.dart';

import 'zone_detail_screen.dart';

class FacilityInspectionScreen extends StatelessWidget {
  final String userId; // Add userId as a parameter

  FacilityInspectionScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facility Inspection'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Low Traffic Areas (Yellow Zone)'),
            onTap: () {
              // Pass userId and zone when navigating
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                    zone: 'Low Traffic Areas (Yellow Zone)',
                    userId: userId, // Pass the userId
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Heavy Traffic Areas (Orange Zone)'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                    zone: 'Heavy Traffic Areas (Orange Zone)',
                    userId: userId, // Pass the userId
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Food Service Areas (Green Zone)'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                    zone: 'Food Service Areas (Green Zone)',
                    userId: userId, // Pass the userId
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('High Microbial Areas (Red Zone)'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                    zone: 'High Microbial Areas (Red Zone)',
                    userId: userId, // Pass the userId
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Outdoors & Exteriors (Black Zone)'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                    zone: 'Outdoors & Exteriors (Black Zone)',
                    userId: userId, // Pass the userId
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
