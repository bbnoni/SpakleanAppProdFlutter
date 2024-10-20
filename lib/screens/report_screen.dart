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

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/tasks',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasks = data['tasks'];

        // Fetch zone score and facility score dynamically for each task
        for (var task in tasks) {
          if (task['zone_score'] == null || task['facility_score'] == null) {
            final zoneName = task['zone_name'];

            if (zoneName != null && zoneName.isNotEmpty) {
              // Encode the URL to handle special characters (e.g., spaces)
              final zoneScoreUrl = Uri.encodeFull(
                  'https://spaklean-app-prod.onrender.com/api/zones/$zoneName/score');
              final zoneScoreResponse = await http.get(Uri.parse(zoneScoreUrl));

              if (zoneScoreResponse.statusCode == 200) {
                final zoneScoreData = jsonDecode(zoneScoreResponse.body);
                task['zone_score'] = zoneScoreData['zone_score'];
              }
            }

            // Fetch facility score
            final facilityScoreResponse = await http.get(
              Uri.parse(
                  'https://spaklean-app-prod.onrender.com/api/facility/score'),
            );

            if (facilityScoreResponse.statusCode == 200) {
              final facilityScoreData = jsonDecode(facilityScoreResponse.body);
              task['facility_score'] =
                  facilityScoreData['total_facility_score'];
            }
          }
        }

        setState(() {
          _tasks = tasks;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final zoneName = task['zone_name'] ?? 'N/A';
    final zoneScore = task['zone_score'] != null
        ? '${double.tryParse(task['zone_score'].toString())?.toStringAsFixed(2) ?? 'N/A'}%'
        : 'N/A';
    final facilityScore = task['facility_score'] != null
        ? '${double.tryParse(task['facility_score'].toString())?.toStringAsFixed(2) ?? 'N/A'}%'
        : 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 8.0),
            Text('Date: ${task['date_submitted']}'),
            Text('Room Score: ${task['room_score']?.toStringAsFixed(2)}%'),
            Text('Zone: $zoneName'),
            Text(
                'Zone Score: $zoneScore'), // Display zone score with 2 decimal places
            Text(
                'Facility Score: $facilityScore'), // Display facility score with 2 decimal places
            Text('Latitude: ${task['latitude']}'),
            Text('Longitude: ${task['longitude']}'),
            const SizedBox(height: 8.0),
            Text('Area Scores:'),
            ...task['area_scores'].entries.map((entry) {
              return Text(
                  '${entry.key}: ${(entry.value as double).toStringAsFixed(2)}%');
            }).toList(),
          ],
        ),
      ),
    );
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
                    return _buildTaskCard(_tasks[index]);
                  },
                ),
    );
  }
}
