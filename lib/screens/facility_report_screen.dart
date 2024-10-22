import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FacilityReportScreen extends StatefulWidget {
  final String userId; // User ID
  final String officeId; // Office ID

  const FacilityReportScreen({
    super.key,
    required this.userId,
    required this.officeId,
  });

  @override
  _FacilityReportScreenState createState() => _FacilityReportScreenState();
}

class _FacilityReportScreenState extends State<FacilityReportScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _facilityData = {}; // To store facility data
  List<dynamic> _zones = []; // To store the zone information
  double? totalFacilityScore;

  @override
  void initState() {
    super.initState();
    _fetchFacilityReport(); // Fetch the facility report when the screen loads
  }

  // Fetch the facility report
  Future<void> _fetchFacilityReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/offices/${widget.officeId}/facility_report'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _facilityData = data; // Store the facility report data
          _zones = data['zones']; // Store zone-specific data
          totalFacilityScore = data['total_facility_score']; // Get total score
        });
      } else {
        _showError('Failed to load facility report');
      }
    } catch (e) {
      _showError('An error occurred while fetching the facility report');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show an error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _facilityData.isEmpty
              ? const Center(child: Text('No report data available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Facility Score: ${totalFacilityScore?.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Zone Breakdown:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Display zone data with scores
                      Expanded(
                        child: ListView.builder(
                          itemCount: _zones.length,
                          itemBuilder: (context, index) {
                            final zone = _zones[index];
                            return ListTile(
                              title: Text(
                                '${zone['zone_name']} - Score: ${zone['zone_score'].toStringAsFixed(2)}%',
                                style: const TextStyle(fontSize: 18),
                              ),
                              subtitle: Text(
                                'Rooms: ${zone['room_names'].join(', ')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // You can add navigation to specific zone details if necessary
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
