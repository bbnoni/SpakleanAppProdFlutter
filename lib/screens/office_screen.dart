import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;

import 'login_screen.dart'; // Import the login screen
import 'scoreboard_screen.dart'; // Import the ScoreboardScreen

class OfficeScreen extends StatefulWidget {
  final String userId; // Add userId as a parameter to OfficeScreen

  const OfficeScreen({super.key, required this.userId});

  @override
  _OfficeScreenState createState() => _OfficeScreenState();
}

class _OfficeScreenState extends State<OfficeScreen> {
  List<dynamic> _assignedOffices = []; // To store fetched offices
  bool _isLoading = false;
  final storage = const FlutterSecureStorage(); // Secure storage instance

  @override
  void initState() {
    super.initState();
    _fetchAssignedOffices(); // Fetch assigned offices when the screen loads
  }

  // Fetch the offices assigned to the logged-in custodian
  Future<void> _fetchAssignedOffices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/offices'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _assignedOffices = data['offices'];
        });
      } else {
        _showError('Failed to load assigned offices');
      }
    } catch (e) {
      _showError('An error occurred while fetching offices');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to handle logout
  Future<void> _logout() async {
    // Clear the access token from secure storage
    await storage.delete(key: 'access_token');

    // Navigate to the login screen and clear the navigation stack
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // Remove all routes
    );
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
        title: const Text("Assigned Offices"),
        actions: [
          // Popup menu for logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle,
                size: 30), // Face icon for logout
            onSelected: (String value) {
              if (value == 'logout') {
                _logout(); // Log out when 'Logout' is selected
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                height: 40, // Reduce the height of the menu item
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            offset: const Offset(0, 50), // Offset to prevent covering the icon
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedOffices.isEmpty
              ? const Center(child: Text('No offices assigned to you.'))
              : ListView.builder(
                  itemCount: _assignedOffices.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            _assignedOffices[index]['name'],
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Tap to view more details',
                            style: TextStyle(fontSize: 14.0),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                          ),
                          tileColor: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          onTap: () {
                            // Navigate to ScoreboardScreen and pass the userId and officeId
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScoreboardScreen(
                                  userId: widget.userId, // Pass the userId
                                  officeId: _assignedOffices[index]['id']
                                      .toString(), // Pass the officeId
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
