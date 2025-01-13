import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CustomerPage extends StatelessWidget {
  final String userId;

  const CustomerPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final locations = [
      'Freezones',
      'Colleges',
      'Aviation',
      'Facility Maintenance',
      'Accra North',
      'Accra South',
      'Accra West',
      'Accra East',
      'Outstation',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Manager - Locations'),
        actions: [
          const LogoutButton(),
        ],
      ),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(locations[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SectorPage(
                    location: locations[index],
                    userId: userId,
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

class SectorPage extends StatelessWidget {
  final String location;
  final String userId;

  const SectorPage({super.key, required this.location, required this.userId});

  @override
  Widget build(BuildContext context) {
    final sectors = [
      'Manufacturing',
      'Education',
      'Airlines',
      'Banking',
      'Health',
      'Non-Banking',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Sectors in $location'),
        actions: [
          const LogoutButton(),
        ],
      ),
      body: ListView.builder(
        itemCount: sectors.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(sectors[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerSelectionPage(
                    location: location,
                    sector: sectors[index],
                    userId: userId,
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

class CustomerSelectionPage extends StatelessWidget {
  final String location;
  final String sector;
  final String userId;

  const CustomerSelectionPage({
    super.key,
    required this.location,
    required this.sector,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final customers = [
      'Barry Callebaut',
      'Lincoln Community School',
      'Ghana Airport Company',
      'GCB',
      'Airport Clinic, KIA',
      'UMB',
      'Enterprise Group',
      'New York University',
      'ABSA',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Customers in $sector'),
        actions: [
          const LogoutButton(),
        ],
      ),
      body: ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(customers[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuildingSelectionPage(
                    location: location,
                    sector: sector,
                    customer: customers[index],
                    userId: userId,
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

class BuildingSelectionPage extends StatelessWidget {
  final String location;
  final String sector;
  final String customer;
  final String userId;

  const BuildingSelectionPage({
    super.key,
    required this.location,
    required this.sector,
    required this.customer,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final buildings = [
      'Absa, East Legon',
      'Absa, Haatso',
      'Absa, Legon Campus',
      'Absa, Legon Main',
      'Absa, Madina',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Buildings for $customer'),
        actions: [
          const LogoutButton(),
        ],
      ),
      body: ListView.builder(
        itemCount: buildings.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(buildings[index]),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected: ${buildings[index]}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        final storage = FlutterSecureStorage();
        await storage.deleteAll(); // Clear all stored data

        // Navigate back to the LoginPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false, // Remove all previous screens
        );
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: const Center(
        child: Text('Login Page'),
      ),
    );
  }
}
