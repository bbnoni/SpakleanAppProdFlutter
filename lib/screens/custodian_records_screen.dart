import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustodianRecordsScreen extends StatefulWidget {
  final String userId;
  final String officeId;

  const CustodianRecordsScreen(
      {super.key, required this.userId, required this.officeId});

  @override
  _CustodianRecordsScreenState createState() => _CustodianRecordsScreenState();
}

class _CustodianRecordsScreenState extends State<CustodianRecordsScreen> {
  List<dynamic> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  // Fetch the submitted task records from the backend
  Future<void> _fetchRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/tasks'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _records = data['tasks']; // Store the fetched tasks
        });
      } else {
        _showError('Failed to load custodian records.');
      }
    } catch (e) {
      _showError('An error occurred while fetching custodian records.');
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
        title: const Text("Custodian Records"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No records found.'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            'Task Type: ${_records[index]['task_type']}',
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Submitted on: ${_records[index]['date_submitted']}',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.black54,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          tileColor: Colors.grey.shade100,
                          onTap: () {
                            // You can implement further details or actions here
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
