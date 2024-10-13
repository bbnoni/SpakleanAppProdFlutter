import 'package:flutter/material.dart';

class RoomListScreen extends StatelessWidget {
  final String zoneName;
  final List<String> rooms;

  RoomListScreen({required this.zoneName, required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rooms in $zoneName')),
      body: rooms.isEmpty
          ? Center(child: Text('No rooms assigned for this zone.'))
          : ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(rooms[index]),
                  onTap: () {
                    // Future logic for navigating to room details
                  },
                );
              },
            ),
    );
  }
}
