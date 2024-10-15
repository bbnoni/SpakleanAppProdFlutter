// lib/screens/rooms_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RoomsScreen extends StatefulWidget {
  final String zone; // The zone selected from the FacilityInspectionScreen

  const RoomsScreen({super.key, required this.zone});

  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<dynamic> rooms = [];
  bool _isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    _fetchRooms(); // Fetch rooms when the screen loads
  }

  // Fetch the rooms for the selected zone
  Future<void> _fetchRooms() async {
    final response = await http.get(
      Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/user/rooms?zone=${widget.zone}'),
    );

    if (response.statusCode == 200) {
      final roomsData = jsonDecode(response.body);
      setState(() {
        rooms = roomsData['rooms']; // Assuming the API returns a list of rooms
        _isLoading = false;
      });
    } else {
      // Handle API error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch rooms')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.zone} Zone Rooms'),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching rooms
          : ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ListTile(
                  title: Text(room['name']), // Display room name
                  onTap: () {
                    // Handle room tap, e.g., navigate to room details
                  },
                );
              },
            ),
    );
  }
}
