import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportScreen extends StatefulWidget {
  final String userId;
  const ReportScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = false;
  double? facilityScore;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchFacilityScore();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/tasks'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tasks = data['tasks'];
        });
      } else {
        _showError('Failed to load tasks');
      }
    } catch (e) {
      _showError('An error occurred while fetching tasks');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFacilityScore() async {
    try {
      final response = await http.get(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/facility/score'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          facilityScore = data['total_facility_score'];
        });
      } else {
        _showError('Failed to load facility score');
      }
    } catch (e) {
      _showError('An error occurred while fetching facility score');
    }
  }

  Future<double> _fetchZoneScore(String zoneName) async {
    final response = await http.get(
      Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/zones/$zoneName/score'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['zone_score'];
    } else {
      throw Exception('Failed to load zone score');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Reports'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? const Center(child: Text('No tasks found'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    final zoneName = task['zone_name'] ?? 'N/A';

                    return FutureBuilder<double>(
                      future: zoneName != 'N/A'
                          ? _fetchZoneScore(zoneName)
                          : Future.value(
                              0.0), // Return 0.0 when zoneName is 'N/A'
                      builder: (context, snapshot) {
                        final zoneScore =
                            snapshot.data?.toStringAsFixed(2) ?? 'N/A';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 6.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task Type: ${task['task_type']}',
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Date: ${task['date_submitted']}'),
                                Text(
                                    'Room Score: ${task['room_score']?.toStringAsFixed(2)}%'),
                                Text('Zone: $zoneName'),
                                Text('Latitude: ${task['latitude']}'),
                                Text('Longitude: ${task['longitude']}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Zone Score: $zoneScore%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (facilityScore != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total Facility Score: ${facilityScore!.toStringAsFixed(2)}%',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text('Area Scores:'),
                                for (var entry
                                    in (task['area_scores'] as Map).entries)
                                  Text(
                                      '${entry.key}: ${(entry.value as double).toStringAsFixed(2)}%'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
