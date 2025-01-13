import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:spaklean_app/screens/sectors_screen.dart';

class LocationScreen extends StatefulWidget {
  final int userId;

  const LocationScreen({super.key, required this.userId});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _storage = const FlutterSecureStorage();
  Future<List<dynamic>>? _locationsFuture;

  @override
  void initState() {
    super.initState();
    _locationsFuture = _fetchLocations();
  }

  Future<List<dynamic>> _fetchLocations() async {
    try {
      final accessToken =
          await _storage.read(key: 'access_token'); // Using the token
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/locations'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('locations') && data['locations'] != null) {
          return data['locations'];
        } else {
          throw Exception("No locations available");
        }
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      print('Error fetching locations: $e');
      return []; // Return an empty list instead of null to avoid the error
    }
  }

  void _logout() async {
    await _storage.deleteAll(); // Clear storage
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login'); // Navigate back to login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: FutureBuilder<List<dynamic>>(
        future: _locationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No locations assigned'));
          }

          final locations = snapshot.data!;
          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                title: Text(location['name']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SectorScreen(
                        userId: widget.userId,
                        locationId: location['id'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
