import 'dart:convert'; // For decoding the response

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'package:http/http.dart' as http;

import 'change_password_screen.dart'; // Import the ChangePasswordScreen
import 'office_screen.dart'; // Import OfficeScreen to pass user_id

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage(); // Secure storage instance
  bool _isLoading = false; // To show loading indicator during login

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    // Check if fields are empty
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

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
        final userId = responseData['user_id'];
        final accessToken = responseData['access_token']; // Fetch access token
        final passwordChangeRequired = responseData['password_change_required'];

        if (userId == null) {
          throw Exception("User ID is null");
        }

        // Store access token securely
        await _storage.write(key: 'access_token', value: accessToken);

        // If password change is required, navigate to change password screen
        if (passwordChangeRequired == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChangePasswordScreen(userId: userId.toString()),
            ),
          );
          return; // Stop further navigation
        }

        // Navigate based on role
        if (!mounted) return;
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
              content: Text('Login failed. Please check your credentials.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spaklean Login"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 32), // Add spacing
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                ),
              ),
              const SizedBox(height: 16), // Add spacing between input fields
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                ),
              ),
              const SizedBox(height: 24), // Add more space above login button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator()) // Loading indicator
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
