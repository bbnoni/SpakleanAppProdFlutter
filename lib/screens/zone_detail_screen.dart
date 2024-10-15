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
                    return ListTile(
                      title: Text(_rooms[index]['name']),
                      subtitle: Text('Zone: ${_rooms[index]['zone']}'),
                      onTap: () {
                        // Navigate to CheckpointScreen when a room is tapped
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckpointScreen(
                              roomId: _rooms[index]['id']
                                  .toString(), // Pass room ID
                              roomName: _rooms[index]['name'], // Pass room name
                              userId: widget.userId, // Pass userId
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
