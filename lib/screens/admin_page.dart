import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _officeController = TextEditingController();
  final _roomController = TextEditingController();
  List<dynamic> _users = []; // List to store users
  String? _selectedUser; // Currently selected user
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

  // Method to create a new office and assign it to the selected user
  Future<void> _createOffice() async {
    final officeName = _officeController.text;
    final userId = _selectedUser; // Get the selected user ID

    if (officeName.isEmpty || userId == null) {
      _showError('Please enter an office name and select a user.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/admin/create_office'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': officeName,
          'user_id': userId, // Pass the selected user ID
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('Office created and assigned successfully.');
      } else {
        _showError('Failed to create office');
      }
    } catch (e) {
      _showError('An error occurred while creating the office.');
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
            DropdownButton<String>(
              value: _selectedUser,
              hint: Text('Select a User to Assign Office'),
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
            SizedBox(height: 10),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createOffice,
                    child: Text('Create Office and Assign to User'),
                  ),
          ],
        ),
      ),
    );
  }
}
