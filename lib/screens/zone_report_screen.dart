import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ZoneReportScreen extends StatefulWidget {
  final String zoneName;
  final String userId;
  final String officeId;

  const ZoneReportScreen({
    super.key,
    required this.zoneName,
    required this.userId,
    required this.officeId,
  });

  @override
  _ZoneReportScreenState createState() => _ZoneReportScreenState();
}

class _ZoneReportScreenState extends State<ZoneReportScreen> {
  List<dynamic> _rooms = [];
  double _zoneScore = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRoomScores();
  }

  // Fetch room scores for the specific zone and calculate the zone score
  Future<void> _fetchRoomScores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/offices/${widget.officeId}/rooms/${widget.zoneName}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rooms = data['rooms'];
        });

        // Calculate zone score (average of room scores)
        double totalScore = 0.0;
        int roomCount = _rooms.length;

        for (var room in _rooms) {
          totalScore += await _fetchRoomScore(room['id']);
        }

        setState(() {
          _zoneScore = roomCount > 0 ? totalScore / roomCount : 0.0;
        });
      } else {
        _showError('Failed to load rooms for this zone');
      }
    } catch (e) {
      _showError('An error occurred while fetching room scores');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch room report to get the room score
  Future<double> _fetchRoomScore(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/rooms/$roomId/report'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['room_score'] ?? 0.0; // Return the room score
      }
    } catch (e) {
      // Handle error silently for now
    }

    return 0.0; // Default score if fetching fails
  }

  // Show an error message
  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zone Report: ${widget.zoneName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone: ${widget.zoneName}',
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Zone Score: ${_zoneScore.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _rooms.length,
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        return ListTile(
                          title: Text(room['name']),
                          subtitle: Text(
                              'Room Score: ${room['room_score'] ?? 'Not available'}'),
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
