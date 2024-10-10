// lib/screens/admin_page.dart
import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  final _officeController = TextEditingController();
  final _roomController = TextEditingController();

  void _createOffice() {
    // Simulate creation of office (later connect to API)
  }

  void _assignRoomToUser() {
    // Simulate assigning room to user (later connect to API)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _officeController,
              decoration: InputDecoration(labelText: 'Create New Office'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _createOffice,
              child: Text('Create Office'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _roomController,
              decoration: InputDecoration(labelText: 'Assign Room to User'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _assignRoomToUser,
              child: Text('Assign Room'),
            ),
          ],
        ),
      ),
    );
  }
}
