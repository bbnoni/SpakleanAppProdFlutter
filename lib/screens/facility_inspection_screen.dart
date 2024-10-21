import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'report_screen.dart'; // Import ReportScreen
import 'zone_detail_screen.dart';

class FacilityInspectionScreen extends StatefulWidget {
  final String userId; // Add userId as a parameter
  final String officeId; // Add officeId as a parameter

  const FacilityInspectionScreen(
      {super.key, required this.userId, required this.officeId});

  @override
  _FacilityInspectionScreenState createState() =>
      _FacilityInspectionScreenState();
}

class _FacilityInspectionScreenState extends State<FacilityInspectionScreen> {
  double? _facilityScore; // Store facility score
  bool _isLoading = false; // Loading indicator for fetching the score

  @override
  void initState() {
    super.initState();
    _fetchFacilityScore(); // Fetch facility score when the screen loads
  }

  // Fetch facility score for the selected office
  Future<void> _fetchFacilityScore() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Add the officeId as a query parameter to fetch the score specific to that office
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/facility/score?office_id=${widget.officeId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Set facility score or N/A if no score is available
          _facilityScore = data['total_facility_score'] == null
              ? null
              : data['total_facility_score'];
        });
      } else {
        print('Failed to load facility score');
      }
    } catch (e) {
      print('Error fetching facility score: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Inspection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            // Display loading indicator while fetching the score
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              // Display facility score at the top if available, otherwise show N/A
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _facilityScore != null
                      ? 'Total Facility Score: ${_facilityScore!.toStringAsFixed(2)}%'
                      : 'Total Facility Score: N/A',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            Expanded(
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
                  _buildReportTile(
                    context,
                    'Inspection Reports',
                    Colors.white,
                    Icons.report,
                    textColor: Colors.black,
                    userId: widget.userId, // Pass userId to ReportScreen
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ZoneDetailScreen(
              zone: zone,
              userId: widget.userId,
              officeId: widget.officeId, // Pass officeId to ZoneDetailScreen
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

  Widget _buildReportTile(
    BuildContext context,
    String title,
    Color bgColor,
    IconData icon, {
    Color textColor = Colors.white,
    required String userId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              userId: userId,
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
