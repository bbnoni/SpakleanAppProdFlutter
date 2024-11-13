import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ScoreSummaryScreen extends StatefulWidget {
  final String userId;

  const ScoreSummaryScreen({super.key, required this.userId});

  @override
  _ScoreSummaryScreenState createState() => _ScoreSummaryScreenState();
}

class _ScoreSummaryScreenState extends State<ScoreSummaryScreen> {
  Map<String, dynamic>? _scores; // Store fetched scores here
  bool _isLoading = true; // Loading indicator
  String? _errorMessage; // Error message

  @override
  void initState() {
    super.initState();
    _fetchScoreSummary();
  }

  // Fetch score summary data from the backend
  Future<void> _fetchScoreSummary() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/score_summary?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _scores = data; // Set the fetched data
          _isLoading = false; // Stop loading indicator
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load scores. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while fetching scores: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!)) // Show error message
                : _buildScoreTable(), // Build score table if data is fetched
      ),
    );
  }

  Widget _buildScoreTable() {
    return Table(
      border: TableBorder.all(),
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
      },
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text('Zone', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Your Score',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Company/Office Score',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Sector Score',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ..._scores!.keys.map((zone) {
          final zoneScores = _scores![zone];
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(zone),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${zoneScores['yourScore']}%'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${zoneScores['companyScore']}%'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${zoneScores['sectorScore']}%'),
              ),
            ],
          );
        }),
      ],
    );
  }
}
