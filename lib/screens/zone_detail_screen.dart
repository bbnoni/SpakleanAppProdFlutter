// lib/screens/zone_detail_screen.dart
import 'package:flutter/material.dart';

class ZoneDetailScreen extends StatelessWidget {
  final String zone;

  ZoneDetailScreen({required this.zone}); // Pass the zone name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(zone), // Display the zone name in the title
      ),
      body: Center(
        child: Text(
          'Details for $zone',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
