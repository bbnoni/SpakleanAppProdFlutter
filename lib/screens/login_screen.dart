import 'dart:convert'; // For decoding the response

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Add this for making HTTP requests

import 'office_screen.dart'; // Import OfficeScreen to pass user_id

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final role = responseData['role'];
        final userId =
            responseData['user_id']; // Ensure user_id is fetched properly

        if (userId == null) {
          throw Exception("User ID is null");
        }

        // Navigate based on role
        if (!mounted) return; // Ensure widget is still in the widget tree
        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'Custodian') {
          // Pass userId to the OfficeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OfficeScreen(
                  userId:
                      userId.toString()), // Ensure userId is passed as a string
            ),
          );
        }
      } else {
        // Handle login error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Login failed. Please check your credentials.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spaklean Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
