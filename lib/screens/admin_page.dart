import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _officeController = TextEditingController();
  final _roomController = TextEditingController();
  List<dynamic> _users = []; // List to store users
  String? _selectedUser; // Currently selected user
  String? _selectedZone; // Currently selected zone
  final List<String> _zones = [
    'Low Traffic Areas (Yellow Zone)',
    'Heavy Traffic Areas (Orange Zone)',
    'Food Service Areas (Green Zone)',
    'High Microbial Areas (Red Zone)',
    'Outdoors & Exteriors (Black Zone)'
  ]; // Available zones
  bool _isLoading = false; // Loading indicator for API requests

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the admin page loads
  }

  // Fetch list of users from the backend
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/admin/users'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = data['users'];
        });
      } else {
        _showError('Failed to load users');
      }
    } catch (e) {
      _showError('An error occurred while fetching users');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to create a new office and room, assigning it to the selected user and zone
  Future<void> _createOfficeAndRoom() async {
    final officeName = _officeController.text;
    final roomName = _roomController.text;
    final userId = _selectedUser; // Get the selected user ID
    final zone = _selectedZone; // Get the selected zone

    if (officeName.isEmpty ||
        roomName.isEmpty ||
        userId == null ||
        zone == null) {
      _showError('Please enter all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/admin/create_office_and_room'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'office_name': officeName,
          'room_name': roomName,
          'user_id': userId, // Pass the selected user ID
          'zone': zone // Pass the selected zone
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('Office and room created and assigned successfully.');
      } else {
        _showError('Failed to create office and room.');
      }
    } catch (e) {
      _showError('An error occurred while creating the office and room.');
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

  // Show a success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _officeController,
              decoration: const InputDecoration(labelText: 'Create New Office'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(labelText: 'Create New Room'),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedUser,
              hint: const Text('Select a User to Assign Office and Room'),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedUser = newValue;
                });
              },
              items: _users.map((user) {
                return DropdownMenuItem<String>(
                  value: user['id'].toString(),
                  child: Text(user['username']),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedZone,
              hint: const Text('Select a Zone'),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedZone = newValue;
                });
              },
              items: _zones.map((zone) {
                return DropdownMenuItem<String>(
                  value: zone,
                  child: Text(zone),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createOfficeAndRoom,
                    child:
                        const Text('Create Office, Room, and Assign to User'),
                  ),
          ],
        ),
      ),
    );
  }
}
