import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BuildingScreen extends StatelessWidget {
  final int userId;
  final int customerId;

  const BuildingScreen(
      {super.key, required this.userId, required this.customerId});

  Future<List<dynamic>> _fetchBuildings() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/admin/buildings/$customerId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure the response is a list of maps and handled correctly
        if (data is List) {
          return data;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load buildings');
      }
    } catch (e) {
      throw Exception('Error fetching buildings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buildings')),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchBuildings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No buildings found'));
          }

          final buildings = snapshot.data!;
          return ListView.builder(
            itemCount: buildings.length,
            itemBuilder: (context, index) {
              final building = buildings[index];
              return ListTile(
                title: Text(building['name']),
                subtitle: Text('Building ID: ${building['id']}'),
              );
            },
          );
        },
      ),
    );
  }
}
