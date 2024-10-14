import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ZoneDetailScreen extends StatefulWidget {
  final String zone;
  final String userId;

  ZoneDetailScreen(
      {required this.zone, required this.userId}); // Pass both zone and userId

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

  // Fetch rooms for the specific zone and userId
  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/rooms/${widget.zone}'),
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
          ? Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? Center(child: Text('No rooms found for this zone'))
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_rooms[index]['name']),
                      subtitle: Text('Zone: ${_rooms[index]['zone']}'),
                      // Add more details if needed
                    );
                  },
                ),
    );
  }
}
