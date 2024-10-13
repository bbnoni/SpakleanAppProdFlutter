// lib/screens/facility_inspection_screen.dart
import 'package:flutter/material.dart';

import 'zone_detail_screen.dart';

class FacilityInspectionScreen extends StatelessWidget {
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
              // Navigate to the rooms or other details under Low Traffic Areas
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                      zone:
                          'Low Traffic Areas (Yellow Zone)'), // Navigate to the zone-specific screen
                ),
              );
            },
          ),
          ListTile(
            title: Text('Heavy Traffic Areas (Orange Zone)'),
            onTap: () {
              // Future navigation to rooms under Heavy Traffic Areas
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                      zone: 'Heavy Traffic Areas (Orange Zone)'),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Food Service Areas (Green Zone)'),
            onTap: () {
              // Future navigation to rooms under Food Service Areas
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ZoneDetailScreen(zone: 'Food Service Areas (Green Zone)'),
                ),
              );
            },
          ),
          ListTile(
            title: Text('High Microbial Areas (Red Zone)'),
            onTap: () {
              // Future navigation to rooms under High Microbial Areas
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ZoneDetailScreen(zone: 'High Microbial Areas (Red Zone)'),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Outdoors & Exteriors (Black Zone)'),
            onTap: () {
              // Future navigation to rooms under Outdoors & Exteriors
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ZoneDetailScreen(
                      zone: 'Outdoors & Exteriors (Black Zone)'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
