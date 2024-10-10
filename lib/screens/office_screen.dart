// lib/screens/office_screen.dart
import 'package:flutter/material.dart';

class OfficeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Office Screen"),
      ),
      body: Center(
        child: Text("This is the Office Screen where offices will be listed."),
      ),
    );
  }
}
