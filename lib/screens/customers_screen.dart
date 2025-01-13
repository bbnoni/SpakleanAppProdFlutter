import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spaklean_app/screens/buildings_screen.dart';

class CustomerScreen extends StatelessWidget {
  final int userId;
  final int sectorId;

  const CustomerScreen(
      {super.key, required this.userId, required this.sectorId});

  Future<List<dynamic>> _fetchCustomers() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/admin/customers/$sectorId'),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is List) {
          return responseBody; // Proper list response
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      throw Exception('Error fetching customers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No customers found'));
          }

          final customers = snapshot.data!;
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text(customer['name']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuildingScreen(
                        userId: userId,
                        customerId: customer['id'],
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
