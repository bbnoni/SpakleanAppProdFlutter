import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add secure storage for token
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // Add secure storage instance
  final storage = const FlutterSecureStorage();

  // Controllers for Create User Section
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;

  // Controllers for Create Office and Room Section
  final _officeController = TextEditingController();
  final _roomController = TextEditingController();
  String? _selectedUser; // Currently selected user
  String? _selectedZone; // Currently selected zone

  // Controller for Reset Password Section
  final _newPasswordController =
      TextEditingController(); // Controller for new password

  // Available Roles and Zones
  final List<String> _roles = ['Custodian', 'Admin', 'Manager', 'CEO'];
  final List<String> _zones = [
    'Low Traffic Areas (Yellow Zone)',
    'Heavy Traffic Areas (Orange Zone)',
    'Food Service Areas (Green Zone)',
    'High Microbial Areas (Red Zone)',
    'Outdoors & Exteriors (Black Zone)'
  ];

  List<dynamic> _users = []; // List to store users
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

  // Method to create a new user (for the Create User section)
  Future<void> _createUser() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final role = _selectedRole;

    if (username.isEmpty || password.isEmpty || role == null) {
      _showError('Please enter all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'role': role, // Pass the selected role
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('User created successfully.');
        _fetchUsers(); // Refresh the list of users
        _clearUserInput(); // Clear input fields after successful creation
      } else {
        _showError('Failed to create user.');
      }
    } catch (e) {
      _showError('An error occurred while creating the user.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to reset the password of an existing user (no need for current password)
  Future<void> _resetPassword() async {
    final userId = _selectedUser;
    final newPassword = _newPasswordController.text;

    if (userId == null || newPassword.isEmpty) {
      _showError('Please select a user and enter a new password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Retrieve the stored JWT token
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        _showError('You are not authenticated.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/auth/reset_password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Include the JWT token in the headers
        },
        body: jsonEncode({
          'user_id': userId,
          'new_password': newPassword, // Include new password
        }),
      );

      if (response.statusCode == 200) {
        _showSuccess('Password reset successfully.');
        _clearPasswordInput(); // Clear input fields after password reset
      } else {
        _showError('Failed to reset password.');
      }
    } catch (e) {
      _showError('An error occurred while resetting the password.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to create a new office and room (for the Create Office and Room section)
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
        _clearOfficeAndRoomInput(); // Clear input fields after successful creation
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

  // Clear user input fields
  void _clearUserInput() {
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _selectedRole = null;
    });
  }

  // Clear password input fields
  void _clearPasswordInput() {
    _newPasswordController.clear();
  }

  // Clear office and room input fields
  void _clearOfficeAndRoomInput() {
    _officeController.clear();
    _roomController.clear();
    setState(() {
      _selectedUser = null;
      _selectedZone = null;
    });
  }

  // Show an error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show a success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(
            seconds: 2), // Notification disappears after 2 seconds
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Section for creating a new user
              const Text('Create New User',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true, // Hide the password text
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedRole,
                hint: const Text('Select Role'),
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue;
                  });
                },
                items: _roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createUser,
                      child: const Text('Create User'),
                    ),
              const Divider(), // Divider to separate the sections

              // Section for resetting a user's password
              const Text('Reset User Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedUser,
                hint: const Text('Select User to Reset Password'),
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
              TextField(
                controller: _newPasswordController, // Field for new password
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true, // Hide the password text
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _resetPassword,
                      child: const Text('Reset Password'),
                    ),
              const Divider(), // Divider to separate the sections

              // Section for creating a new office and room
              const Text('Create New Office and Room',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _officeController,
                decoration:
                    const InputDecoration(labelText: 'Create New Office'),
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
      ),
    );
  }
}
