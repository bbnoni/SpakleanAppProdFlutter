import 'package:flutter/material.dart';

import 'office_screen.dart'; // Import the office screen

class SectorSelectionScreen extends StatelessWidget {
  final String userId; // We'll still need the userId

  SectorSelectionScreen({Key? key, required this.userId}) : super(key: key);

  // List of available sectors
  final List<String> sectors = [
    'Banking',
    'Manufacturing',
    'Education',
    'Aviation',
    'Residentials',
    'Health',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Sector'),
      ),
      body: ListView.builder(
        itemCount: sectors.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(sectors[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to the OfficeScreen, passing the selected sector
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OfficeScreen(
                    userId: userId,
                    // sector: sectors[index], // Pass the selected sector
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
