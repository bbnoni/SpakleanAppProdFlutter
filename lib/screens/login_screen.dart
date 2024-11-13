import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:spaklean_app/screens/sign_up_screen.dart';

import 'change_password_screen.dart';
import 'office_screen.dart';
import 'user_selection_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check if user is already logged in
  }

  // Check if the token exists on app startup
  Future<void> _checkLoginStatus() async {
    final accessToken = await _storage.read(key: 'access_token');
    final userId = await _storage.read(key: 'currentUserId');
    final role = await _storage.read(key: 'role'); // Read the stored role

    if (accessToken != null && userId != null && role != null) {
      // Route based on role
      if (role == 'Custodial Manager' || role == 'Facility Executive') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserSelectionScreen(
              role: role,
              userId: userId,
            ),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/office',
          arguments: {'userId': userId},
        );
      }
    }
  }

  // Login function
  void _login() async {
    final email = _emailController.text
        .trim()
        .toLowerCase(); // Convert email to lowercase
    final password = _passwordController.text;

    // Check if fields are empty
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final response = await http.post(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final role = responseData['role'];
        final userId = responseData['user_id'];
        final accessToken = responseData['access_token'];
        final passwordChangeRequired = responseData['password_change_required'];

        if (userId == null) {
          throw Exception("User ID is null");
        }

        // Store access token, user ID, and role securely
        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'currentUserId', value: userId.toString());
        await _storage.write(key: 'role', value: role); // Store the role

        // If password change is required, navigate to Change Password screen
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

        // Check the role and navigate accordingly
        if (!mounted) return;
        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'Custodian') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OfficeScreen(userId: userId.toString()),
            ),
          );
        } else if (role == 'CEO') {
          Navigator.pushReplacementNamed(context, '/ceo');
        } else if (role == 'Custodial Manager' ||
            role == 'Facility Executive') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserSelectionScreen(
                role: role,
                userId: userId.toString(),
              ),
            ),
          );
        } else {
          // If the role is not permitted, show a message and do not navigate
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('You do not have permission to access this feature.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Login failed. Please check your credentials.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  // Logout function
  Future<void> _logout() async {
    await _storage.delete(key: 'access_token'); // Clear the access token
    await _storage.delete(key: 'currentUserId'); // Clear the user ID
    await _storage.delete(key: 'role'); // Clear the role
    Navigator.pushReplacementNamed(context, '/login'); // Go to login screen
  }

  // Show a dialog to collect the email address for forgot password
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Forgot Password'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Enter your email',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _forgotPassword(emailController.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Forgot password API call
  Future<void> _forgotPassword(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/auth/forgot_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset link sent to your email.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send password reset email.')),
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
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Image.asset(
                  '/Users/benoniokaikoi/development/playground/spaklean_app/lib/assets/icon/SpakleanLogo.jpeg',
                  height: 80.0,
                  width: 80.0,
                ),
              ),
              const Text(
                'Welcome!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
              // Inside the build method of LoginScreen, below the "Forgot Password?" button:
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: const Text(
                  'Don’t have an account? Sign Up',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
