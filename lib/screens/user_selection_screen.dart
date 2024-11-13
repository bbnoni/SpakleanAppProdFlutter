import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'office_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  final String role;
  final String userId;

  const UserSelectionScreen({
    super.key,
    required this.role,
    required this.userId,
  });

  @override
  _UserSelectionScreenState createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/admin/users'),
      );

      if (response.statusCode == 200) {
        final allUsers = jsonDecode(response.body)['users'];

        // Filter only users with the 'Custodian' role
        final custodianUsers = allUsers.where((user) {
          return user['role'] == 'Custodian';
        }).toList();

        setState(() {
          _users = custodianUsers;
          _filteredUsers =
              List.from(custodianUsers); // Show all custodians initially
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load users')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          final username = user['username'].toString().toLowerCase();
          return username.contains(query);
        }).toList();
      }
    });
  }

  void _navigateToUserOffices(String selectedUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfficeScreen(userId: selectedUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} - Select User'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                hintText: 'Type to search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.separated(
                          itemCount: _filteredUsers.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: Colors.grey),
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return ListTile(
                              title: Text(
                                user['username'],
                                style: const TextStyle(fontSize: 18),
                              ),
                              onTap: () =>
                                  _navigateToUserOffices(user['id'].toString()),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
