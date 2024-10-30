import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'checkpoint_screen.dart';

class ZoneDetailScreen extends StatefulWidget {
  final String zone;
  final String userId;
  final String officeId;

  const ZoneDetailScreen({
    super.key,
    required this.zone,
    required this.userId,
    required this.officeId,
  });

  @override
  _ZoneDetailScreenState createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  List<dynamic> _rooms = [];
  bool _isLoading = false;
  double? _zoneScore;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _fetchZoneScore();
    _startAutoRefresh(); // Start auto-refresh
  }

  // Start auto-refresh to fetch score and rooms periodically
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _fetchZoneScore();
      _fetchRooms();
    });
  }

  // Cancel timer when the widget is disposed to prevent memory leaks
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchZoneScore() async {
    try {
      final encodedZone = Uri.encodeComponent(widget.zone);
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/zones/$encodedZone/score?office_id=${widget.officeId}&user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _zoneScore = data['zone_score'] == "N/A" ? null : data['zone_score'];
        });
      } else {
        print('Failed to load zone score');
      }
    } catch (e) {
      print('Error fetching zone score: $e');
    }
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final encodedZone = Uri.encodeComponent(widget.zone);
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/offices/${widget.officeId}/rooms/$encodedZone'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rooms = data['rooms'];
        });
      } else {
        _showError('Failed to load rooms for this zone');
      }
    } catch (e) {
      _showError('An error occurred while fetching rooms');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getZoneColor(String zone) {
    switch (zone) {
      case 'Low Traffic Areas (Yellow Zone)':
        return Colors.yellow;
      case 'Heavy Traffic Areas (Orange Zone)':
        return Colors.orange;
      case 'Food Service Areas (Green Zone)':
        return Colors.green;
      case 'High Microbial Areas (Red Zone)':
        return Colors.red;
      case 'Outdoors & Exteriors (Black Zone)':
        return Colors.black;
      case 'Inspection Reports':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  Color _getTextColor(String zone) {
    if (zone == 'Outdoors & Exteriors (Black Zone)' ||
        zone == 'Inspection Reports') {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> createRoom(
      String roomName, String zone, String userId, String officeId) async {
    final response = await http.post(
      Uri.parse('https://spaklean-app-prod.onrender.com/api/admin/create_room'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": roomName,
        "zone": zone,
        "office_id": officeId,
        "user_id": userId
      }),
    );

    if (response.statusCode == 201) {
      print('Room created successfully');
      _fetchRooms();
    } else {
      print('Failed to create room: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zone),
      ),
      body: Column(
        children: [
          if (_zoneScore != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Zone Score: ${_zoneScore!.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Zone Score: N/A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                    ? const Center(child: Text('No rooms found for this zone'))
                    : ListView.builder(
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) {
                          final zoneColor = _getZoneColor(widget.zone);
                          final textColor = _getTextColor(widget.zone);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: zoneColor.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.4),
                                    blurRadius: 6.0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  _rooms[index]['name'],
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Zone: ${_rooms[index]['zone']}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: textColor,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckpointScreen(
                                        roomId: _rooms[index]['id'].toString(),
                                        roomName: _rooms[index]['name'],
                                        userId: widget.userId,
                                        zoneName: widget.zone,
                                        officeId: widget.officeId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
