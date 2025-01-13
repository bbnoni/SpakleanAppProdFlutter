import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spaklean_app/screens/customers_screen.dart';

class SectorScreen extends StatelessWidget {
  final int userId;
  final int locationId;

  const SectorScreen(
      {super.key, required this.userId, required this.locationId});

  // Fetch sectors from the backend
  Future<List<dynamic>> _fetchSectors() async {
    final response = await http.get(
      Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/admin/sectors/$locationId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return data;
      } else {
        return []; // Return empty list if no sectors found
      }
    } else {
      throw Exception('Failed to load sectors');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sectors')),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchSectors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No sectors found for this location'));
          }

          final sectors = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Adjust grid columns for better layout
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            itemCount: sectors.length,
            itemBuilder: (context, index) {
              final sector = sectors[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerScreen(
                        userId: userId,
                        sectorId: sector['id'],
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blueAccent,
                  ),
                  child: Center(
                    child: Text(
                      sector['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
