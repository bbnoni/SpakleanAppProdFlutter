import 'package:flutter/material.dart';

import 'zone_detail_screen.dart';

class FacilityInspectionScreen extends StatelessWidget {
  final String userId; // Add userId as a parameter
  final String officeId; // Add officeId as a parameter

  const FacilityInspectionScreen(
      {super.key, required this.userId, required this.officeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Inspection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          children: <Widget>[
            _buildInspectionTile(
              context,
              'Low Traffic Areas\nYellow Zone',
              Colors.yellow,
              Icons.traffic,
              'Low Traffic Areas (Yellow Zone)',
            ),
            _buildInspectionTile(
              context,
              'Heavy Traffic Areas\nOrange Zones',
              Colors.orange,
              Icons.directions_car,
              'Heavy Traffic Areas (Orange Zone)',
            ),
            _buildInspectionTile(
              context,
              'Food Service Areas\nGreen Zone',
              Colors.green,
              Icons.fastfood,
              'Food Service Areas (Green Zone)',
            ),
            _buildInspectionTile(
              context,
              'High Microbial Areas\nRed Zone',
              Colors.red,
              Icons.warning,
              'High Microbial Areas (Red Zone)',
            ),
            _buildInspectionTile(
              context,
              'Outdoors & Exteriors\nBlack Zone',
              Colors.black,
              Icons.park,
              'Outdoors & Exteriors (Black Zone)',
            ),
            _buildInspectionTile(
              context,
              'Inspection Reports',
              Colors.white,
              Icons.report,
              'Inspection Reports',
              textColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  // Reusable method to build grid tiles and navigate
  Widget _buildInspectionTile(
    BuildContext context,
    String title,
    Color bgColor,
    IconData icon,
    String zone, {
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to ZoneDetailScreen and pass the userId, zone, and officeId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ZoneDetailScreen(
              zone: zone, // Pass the zone as the title
              userId: userId, // Pass the userId
              officeId: officeId, // Pass the officeId
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: textColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
