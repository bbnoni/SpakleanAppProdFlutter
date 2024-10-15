import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'checkpoint_screen.dart'; // Import CheckpointScreen

class ZoneDetailScreen extends StatefulWidget {
  final String zone;
  final String userId;
  final String officeId; // Add officeId parameter

  const ZoneDetailScreen(
      {super.key,
      required this.zone,
      required this.userId,
      required this.officeId}); // Pass both zone, userId, and officeId

  @override
  _ZoneDetailScreenState createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  List<dynamic> _rooms = []; // To store the fetched rooms
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRooms(); // Fetch rooms when the screen loads
  }

  // Fetch rooms for the specific zone, userId, and officeId
  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/offices/${widget.officeId}/rooms/${widget.zone}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rooms = data['rooms']; // Store the fetched rooms
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

  // Get background color based on zone type
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
        return Colors.grey; // Default if no match
    }
  }

  // Get text color based on zone background for better contrast
  Color _getTextColor(String zone) {
    if (zone == 'Outdoors & Exteriors (Black Zone)' ||
        zone == 'Inspection Reports') {
      return Colors.white;
    } else {
      return Colors.black;
    }
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
        title: Text(widget.zone), // Display the zone name in the title
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? const Center(child: Text('No rooms found for this zone'))
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final zoneColor = _getZoneColor(widget.zone);
                    final textColor = _getTextColor(widget.zone);
                    return Column(
                      children: [
                        ListTile(
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
                          tileColor: zoneColor.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          onTap: () {
                            // Navigate to CheckpointScreen when a room is tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckpointScreen(
                                  roomId: _rooms[index]['id']
                                      .toString(), // Pass room ID
                                  roomName: _rooms[index]
                                      ['name'], // Pass room name
                                  userId: widget.userId, // Pass userId
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(
                          color: Colors.grey,
                          thickness: 1.0,
                          indent: 16.0,
                          endIndent: 16.0,
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
