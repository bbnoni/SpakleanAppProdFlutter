import 'dart:convert'; // For decoding the response

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Add this for making HTTP requests

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    // Replace with your actual login API URL
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

      // Navigate based on role
      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/admin'); // Admin screen
      } else {
        Navigator.pushReplacementNamed(context, '/office'); // Office screen
      }
    } else {
      // Handle login error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Spaklean Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
