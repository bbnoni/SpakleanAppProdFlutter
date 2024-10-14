import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'scoreboard_screen.dart'; // Import the ScoreboardScreen

class OfficeScreen extends StatefulWidget {
  final String userId; // Add userId as a parameter to OfficeScreen

  OfficeScreen({required this.userId});

  @override
  _OfficeScreenState createState() => _OfficeScreenState();
}

class _OfficeScreenState extends State<OfficeScreen> {
  List<dynamic> _assignedOffices = []; // To store fetched offices
  bool _isLoading = false;

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

  // Show an error message
  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assigned Offices"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _assignedOffices.isEmpty
              ? Center(child: Text('No offices assigned to you.'))
              : ListView.builder(
                  itemCount: _assignedOffices.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_assignedOffices[index]['name']),
                      onTap: () {
                        // Navigate to ScoreboardScreen and pass the userId
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ScoreboardScreen(userId: widget.userId),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
