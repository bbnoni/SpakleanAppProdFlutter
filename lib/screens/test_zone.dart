import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add secure storage for token
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // Add secure storage instance
  final storage = const FlutterSecureStorage();

  // Controllers for Create User Section
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;

  // Controllers for Create Office and Room Section
  final _officeController = TextEditingController();
  final _roomController = TextEditingController();
  final List<String> _addedRooms = [];
  final List<String> _selectedUsers = []; // Now support multiple selected users
  String? _selectedUser; // Currently selected user
  String? _selectedZone; // Currently selected zone
  String? _selectedOffice; // Currently selected office for room assignment
  String? _selectedSector; // Currently selected sector

  // Controller for Reset Password Section
  final _newPasswordController = TextEditingController();

  // Available Roles, Zones, and Sectors
  final List<String> _roles = ['Custodian', 'Admin', 'Manager', 'CEO'];
  final List<String> _zones = [
    'Low Traffic Areas (Yellow Zone)',
    'Heavy Traffic Areas (Orange Zone)',
    'Food Service Areas (Green Zone)',
    'High Microbial Areas (Red Zone)',
    'Outdoors & Exteriors (Black Zone)'
  ];

  final List<String> _sectors = [
    'Banking',
    'Manufacturing',
    'Education',
    'Aviation',
    'Residentials',
    'Health'
  ];

  List<dynamic> _users = [];
  List<dynamic> _offices = [];
  bool _isLoading = false;
  final List<bool> _isExpanded = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users when the admin page loads
    _fetchOffices(); // Fetch list of offices
  }

  // Fetch list of users from the backend
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
          Uri.parse('https://spaklean-app-prod.onrender.com/api/admin/users'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = data['users'];
        });
      } else {
        _showError('Failed to load users');
      }
    } catch (e) {
      _showError('An error occurred while fetching users');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch list of offices from the backend
  Future<void> _fetchOffices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/admin/offices'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _offices = data['offices'];
        });
      } else {
        _showError('Failed to load offices');
      }
    } catch (e) {
      _showError('An error occurred while fetching offices');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to log out the user
  Future<void> _logout() async {
    await storage.delete(key: 'access_token'); // Clear access token
    Navigator.pushReplacementNamed(
        context, '/login'); // Navigate to login screen
  }

  // Method to create a new user (for the Create User section)
  Future<void> _createUser() async {
    final firstName = _firstNameController.text;
    final middleName = _middleNameController.text;
    final lastName = _lastNameController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;
    final role = _selectedRole;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        role == null) {
      _showError('Please enter all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'username': username,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('User created successfully.');
        _fetchUsers(); // Refresh the list of users
        _clearUserInput(); // Clear input fields after successful creation
      } else {
        _showError('Failed to create user.');
      }
    } catch (e) {
      _showError('An error occurred while creating the user.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Clear user input fields
  void _clearUserInput() {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _selectedRole = null;
    });
  }

  // Method to reset the password of an existing user
  Future<void> _resetPassword() async {
    final userId = _selectedUser;
    final newPassword = _newPasswordController.text;

    if (userId == null || newPassword.isEmpty) {
      _showError('Please select a user and enter a new password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        _showError('You are not authenticated.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/auth/reset_password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user_id': userId, 'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        _showSuccess('Password reset successfully.');
        _clearPasswordInput();
      } else {
        _showError('Failed to reset password.');
      }
    } catch (e) {
      _showError('An error occurred while resetting the password.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to create a new office and assign multiple rooms
  Future<void> _createOfficeAndRooms() async {
    final officeName = _officeController.text;
    final zone = _selectedZone;
    final sector = _selectedSector; // Add sector to the request
    final selectedUserIds =
        _selectedUsers; // Ensure multiple users are selected

    if (officeName.isEmpty ||
        selectedUserIds.isEmpty ||
        //zone == null ||
        sector == null) {
      _showError('Please enter all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/admin/create_office_and_room'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'office_name': officeName,
          'room_names': _addedRooms,
          'user_ids': selectedUserIds, // Include the list of user IDs
          'zone': zone,
          'sector': sector // Include sector in the request
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('Office and rooms created and assigned successfully.');
        _clearOfficeAndRoomInput();
      } else {
        _showError('Failed to create office and rooms.');
      }
    } catch (e) {
      _showError('An error occurred while creating the office and rooms.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add room to the list of rooms to be assigned
  void _addRoom() {
    final room = _roomController.text;
    if (room.isNotEmpty) {
      setState(() {
        _addedRooms.add(room);
        _roomController.clear();
      });
    }
  }

  // Method to add additional rooms to an existing user
  Future<void> _addMoreRooms() async {
    final userId = _selectedUser;
    final officeId = _selectedOffice;
    final zone = _selectedZone;

    if (_addedRooms.isEmpty ||
        userId == null ||
        zone == null ||
        officeId == null) {
      _showError('Please enter all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/admin/add_more_rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_names': _addedRooms,
          'user_id': userId,
          'office_id': officeId,
          'zone': zone,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccess('Rooms added to user successfully.');
        _clearRoomInput();
      } else {
        _showError('Failed to add rooms.');
      }
    } catch (e) {
      _showError('An error occurred while adding rooms.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Clear password input fields
  void _clearPasswordInput() {
    _newPasswordController.clear();
  }

  // Clear office and room input fields
  void _clearOfficeAndRoomInput() {
    _officeController.clear();
    _roomController.clear();
    _addedRooms.clear();
    setState(() {
      _selectedUser = null;
      _selectedZone = null;
      _selectedSector = null;
      _selectedUsers.clear(); // Clear selected users
    });
  }

  // Clear room input fields for adding more rooms
  void _clearRoomInput() {
    _roomController.clear();
    _addedRooms.clear();
    setState(() {
      _selectedUser = null;
      _selectedZone = null;
      _selectedOffice = null;
    });
  }

  // Show an error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Show a success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Fetch updated data when refresh button is pressed
              _fetchUsers();
              _fetchOffices();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 30),
            onSelected: (String value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                height: 40,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Logout')
                  ],
                ),
              ),
            ],
            offset: const Offset(0, 50),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isExpanded[index] = !_isExpanded[index];
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (context, isExpanded) {
                      return const ListTile(
                        title: Text('Create New User'),
                      );
                    },
                    body: Column(
                      children: [
                        TextField(
                          controller: _firstNameController,
                          decoration:
                              const InputDecoration(labelText: 'First Name'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _middleNameController,
                          decoration:
                              const InputDecoration(labelText: 'Middle Name'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _lastNameController,
                          decoration:
                              const InputDecoration(labelText: 'Last Name'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          decoration:
                              const InputDecoration(labelText: 'Username'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _selectedRole,
                          hint: const Text('Select Role'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRole = newValue;
                            });
                          },
                          items: _roles.map((role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _createUser,
                                child: const Text('Create User'),
                              ),
                      ],
                    ),
                    isExpanded: _isExpanded[0],
                  ),
                  ExpansionPanel(
                    headerBuilder: (context, isExpanded) {
                      return const ListTile(
                        title: Text('Reset User Password'),
                      );
                    },
                    body: Column(
                      children: [
                        DropdownButton<String>(
                          value: _selectedUser,
                          hint: const Text('Select User to Reset Password'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedUser = newValue;
                            });
                          },
                          items: _users.map((user) {
                            return DropdownMenuItem<String>(
                              value: user['id'].toString(),
                              child: Text(user['username']),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _newPasswordController,
                          decoration:
                              const InputDecoration(labelText: 'New Password'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _resetPassword,
                                child: const Text('Reset Password'),
                              ),
                      ],
                    ),
                    isExpanded: _isExpanded[1],
                  ),
                  ExpansionPanel(
                    headerBuilder: (context, isExpanded) {
                      return const ListTile(
                        title: Text('Create Office'),
                      );
                    },
                    body: Column(
                      children: [
                        TextField(
                          controller: _officeController,
                          decoration: const InputDecoration(
                              labelText: 'Create New Office'),
                        ),
                        // const SizedBox(height: 10),
                        // TextField(
                        //   controller: _roomController,
                        //   decoration: const InputDecoration(
                        //       labelText: 'Create New Room'),
                        // ),
                        // const SizedBox(height: 10),
                        // ElevatedButton(
                        //   onPressed: _addRoom,
                        //   child: const Text('Add Office'),
                        // ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: _addedRooms
                              .map((room) => Chip(label: Text(room)))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: _users.map((user) {
                            return ChoiceChip(
                              label: Text(user['username']),
                              selected: _selectedUsers
                                  .contains(user['id'].toString()),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedUsers.add(user['id'].toString());
                                  } else {
                                    _selectedUsers
                                        .remove(user['id'].toString());
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        // const SizedBox(height: 10),
                        // DropdownButton<String>(
                        //   value: _selectedZone,
                        //   hint: const Text('Select a Zone'),
                        //   isExpanded: true,
                        //   onChanged: (String? newValue) {
                        //     setState(() {
                        //       _selectedZone = newValue;
                        //     });
                        //   },
                        //   items: _zones.map((zone) {
                        //     return DropdownMenuItem<String>(
                        //       value: zone,
                        //       child: Text(zone),
                        //     );
                        //   }).toList(),
                        // ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _selectedSector, // Add sector dropdown
                          hint: const Text('Select a Sector'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSector = newValue;
                            });
                          },
                          items: _sectors.map((sector) {
                            return DropdownMenuItem<String>(
                              value: sector,
                              child: Text(sector),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _createOfficeAndRooms,
                                child: const Text(
                                    'Create Office and Assign to Users'),
                              ),
                      ],
                    ),
                    isExpanded: _isExpanded[2],
                  ),
                  ExpansionPanel(
                    headerBuilder: (context, isExpanded) {
                      return const ListTile(
                        title: Text('Add More Rooms to User'),
                      );
                    },
                    body: Column(
                      children: [
                        DropdownButton<String>(
                          value: _selectedUser,
                          hint: const Text('Select a User to Add Rooms'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedUser = newValue;
                            });
                          },
                          items: _users.map((user) {
                            return DropdownMenuItem<String>(
                              value: user['id'].toString(),
                              child: Text(user['username']),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _selectedOffice,
                          hint: const Text('Select Office for Room Assignment'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedOffice = newValue;
                            });
                          },
                          items: _offices.map((office) {
                            return DropdownMenuItem<String>(
                              value: office['id'].toString(),
                              child: Text(office['name']),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _roomController,
                          decoration:
                              const InputDecoration(labelText: 'Add New Room'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _addRoom,
                          child: const Text('Add Room'),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: _addedRooms
                              .map((room) => Chip(label: Text(room)))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        DropdownButton<String>(
                          value: _selectedZone,
                          hint: const Text('Select a Zone'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedZone = newValue;
                            });
                          },
                          items: _zones.map((zone) {
                            return DropdownMenuItem<String>(
                              value: zone,
                              child: Text(zone),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _addMoreRooms,
                                child: const Text('Add Rooms to User'),
                              ),
                      ],
                    ),
                    isExpanded: _isExpanded[3],
                  ),
                  // New Expansion Panel: Assign Users to Office
                  ExpansionPanel(
                    headerBuilder: (context, isExpanded) {
                      return const ListTile(
                        title: Text('Assign Users to Office'),
                      );
                    },
                    body: Column(
                      children: [
                        DropdownButton<String>(
                          value: _selectedOffice,
                          hint: const Text('Select Office'),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedOffice = newValue;
                            });
                          },
                          items: _offices.map((office) {
                            return DropdownMenuItem<String>(
                              value: office['id'].toString(),
                              child: Text(office['name']),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: _users.map((user) {
                            return ChoiceChip(
                              label: Text(user['username']),
                              selected: _selectedUsers
                                  .contains(user['id'].toString()),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedUsers.add(user['id'].toString());
                                  } else {
                                    _selectedUsers
                                        .remove(user['id'].toString());
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _assignUsersToOffice,
                                child: const Text('Assign Users'),
                              ),
                      ],
                    ),
                    isExpanded: _isExpanded[4],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignUsersToOffice() async {
    final officeId = _selectedOffice;
    final selectedUserIds = _selectedUsers;

    if (officeId == null || selectedUserIds.isEmpty) {
      _showError('Please select an office and at least one user.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/admin/assign_users_to_office'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'office_id': officeId,
          'user_ids': selectedUserIds,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccess('Users assigned to office successfully.');
        _clearUserInput();
      } else {
        _showError('Failed to assign users to office.');
      }
    } catch (e) {
      _showError('An error occurred while assigning users.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
