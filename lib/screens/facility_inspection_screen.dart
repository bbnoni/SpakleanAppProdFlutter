import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'report_screen.dart';
import 'zone_detail_screen.dart';

class FacilityInspectionScreen extends StatefulWidget {
  final String userId;
  final String officeId;

  const FacilityInspectionScreen(
      {super.key, required this.userId, required this.officeId});

  @override
  _FacilityInspectionScreenState createState() =>
      _FacilityInspectionScreenState();
}

class _FacilityInspectionScreenState extends State<FacilityInspectionScreen> {
  double? _facilityScore;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchFacilityScore();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _fetchFacilityScore();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchFacilityScore() async {
    try {
      final currentDate = DateTime.now();
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/facility/score?office_id=${widget.officeId}&user_id=${widget.userId}&month=${currentDate.month}&year=${currentDate.year}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _facilityScore = data['total_facility_score'] != "N/A"
              ? data['total_facility_score']
              : null;
        });
      } else {
        print(
            'Failed to load facility score with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching facility score: $e');
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
                    textColor: Colors.black,
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
                    userId: widget.userId,
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
              officeId: widget.officeId,
              currentUserId: widget.userId, // Pass currentUserId here
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
