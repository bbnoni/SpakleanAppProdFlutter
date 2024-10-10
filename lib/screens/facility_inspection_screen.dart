// lib/screens/facility_inspection_screen.dart
import 'package:flutter/material.dart';

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
              // Future navigation to rooms under Low Traffic Areas
              Navigator.pushNamed(context, '/rooms'); // Example
            },
          ),
          ListTile(
            title: Text('Heavy Traffic Areas (Orange Zone)'),
            onTap: () {
              // Future navigation to rooms under Heavy Traffic Areas
            },
          ),
          ListTile(
            title: Text('Food Service Areas (Green Zone)'),
            onTap: () {
              // Future navigation to rooms under Food Service Areas
            },
          ),
          ListTile(
            title: Text('High Microbial Areas (Red Zone)'),
            onTap: () {
              // Future navigation to rooms under High Microbial Areas
            },
          ),
          ListTile(
            title: Text('Outdoors & Exteriors (Black Zone)'),
            onTap: () {
              // Future navigation to rooms under Outdoors & Exteriors
            },
          ),
        ],
      ),
    );
  }
}
