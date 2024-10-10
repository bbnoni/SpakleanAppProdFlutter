import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://localhost:5000/api'; // Change this to your Flask backend URL

  static Future<http.Response> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(
          <String, String>{'username': username, 'password': password}),
    );
    return response;
  }

  // Add other methods like task submission, fetching rooms, etc.
}
