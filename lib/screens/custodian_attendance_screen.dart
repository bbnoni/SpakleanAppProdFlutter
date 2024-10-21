import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CustodianAttendanceScreen extends StatefulWidget {
  final String userId;
  final String officeId;

  const CustodianAttendanceScreen({
    super.key,
    required this.userId,
    required this.officeId,
  });

  @override
  _CustodianAttendanceScreenState createState() =>
      _CustodianAttendanceScreenState();
}

class _CustodianAttendanceScreenState extends State<CustodianAttendanceScreen> {
  DateTime? checkInTime;
  DateTime? checkOutTime;
  double? checkInLat;
  double? checkInLong;
  double? checkOutLat;
  double? checkOutLong;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatusFromPrefs();
    _fetchAttendanceStatus();
  }

  // Load attendance status from SharedPreferences
  Future<void> _loadAttendanceStatusFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey('checkInTime')) {
        checkInTime = DateTime.parse(prefs.getString('checkInTime')!);
        checkInLat = prefs.getDouble('checkInLat');
        checkInLong = prefs.getDouble('checkInLong');
      }
      if (prefs.containsKey('checkOutTime')) {
        checkOutTime = DateTime.parse(prefs.getString('checkOutTime')!);
        checkOutLat = prefs.getDouble('checkOutLat');
        checkOutLong = prefs.getDouble('checkOutLong');
      }
    });
  }

  // Save attendance status to SharedPreferences
  Future<void> _saveAttendanceStatusToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (checkInTime != null) {
      prefs.setString('checkInTime', checkInTime!.toIso8601String());
      prefs.setDouble('checkInLat', checkInLat ?? 0);
      prefs.setDouble('checkInLong', checkInLong ?? 0);
    }
    if (checkOutTime != null) {
      prefs.setString('checkOutTime', checkOutTime!.toIso8601String());
      prefs.setDouble('checkOutLat', checkOutLat ?? 0);
      prefs.setDouble('checkOutLong', checkOutLong ?? 0);
    }
  }

  // Clear attendance status from SharedPreferences
  Future<void> _clearAttendanceStatusFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('checkInTime');
    prefs.remove('checkInLat');
    prefs.remove('checkInLong');
    prefs.remove('checkOutTime');
    prefs.remove('checkOutLat');
    prefs.remove('checkOutLong');
  }

  // Fetch attendance status from DB
  Future<void> _fetchAttendanceStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/attendance/status?user_id=${widget.userId}&office_id=${widget.officeId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['check_in_time'] != null) {
          setState(() {
            checkInTime = DateTime.parse(data['check_in_time']);
            checkInLat = data['check_in_lat'];
            checkInLong = data['check_in_long'];
            checkOutTime = data['check_out_time'] != null
                ? DateTime.parse(data['check_out_time'])
                : null;
            checkOutLat = data['check_out_lat'];
            checkOutLong = data['check_out_long'];

            _saveAttendanceStatusToPrefs(); // Save status locally
          });
        }
      }
    } catch (e) {
      print("Error fetching attendance status: $e");
    }
  }

  // Fetch location from the API
  Future<void> _fetchLocation() async {
    try {
      final response = await http.get(Uri.parse('https://ipinfo.io/json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["loc"] != null) {
          final loc = data["loc"].split(',');
          final lat = double.tryParse(loc[0]);
          final long = double.tryParse(loc[1]);

          setState(() {
            if (checkInTime == null) {
              checkInLat = lat;
              checkInLong = long;
              checkInTime = DateTime.now(); // Capture check-in time
            } else if (checkOutTime == null) {
              checkOutLat = lat;
              checkOutLong = long;
              checkOutTime = DateTime.now(); // Capture check-out time
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  // Submit attendance (check-in or check-out)
  Future<void> _submitAttendance({required bool isCheckIn}) async {
    setState(() {
      _isLoading = true;
    });

    final data = {
      "user_id": widget.userId,
      "office_id": widget.officeId,
      "check_in_time": checkInTime?.toIso8601String(),
      "check_in_lat": checkInLat,
      "check_in_long": checkInLong,
      "check_out_time": checkOutTime?.toIso8601String(),
      "check_out_lat": checkOutLat,
      "check_out_long": checkOutLong,
    };

    final url = isCheckIn
        ? 'https://spaklean-app-prod.onrender.com/api/attendance/checkin'
        : 'https://spaklean-app-prod.onrender.com/api/attendance/checkout';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isCheckIn ? 'Checked In!' : 'Checked Out!')),
        );
        if (!isCheckIn) {
          _clearAttendanceStatusFromPrefs(); // Clear state after check-out
          setState(() {
            checkInTime = null;
            checkOutTime = null;
          });
        } else {
          _saveAttendanceStatusToPrefs(); // Save state after check-in
        }
      } else {
        print("Failed to submit attendance: ${response.body}");
      }
    } catch (e) {
      print("Error submitting attendance: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAttendanceButton() {
    return ElevatedButton.icon(
      onPressed: checkInTime == null
          ? () async {
              await _fetchLocation();
              await _submitAttendance(isCheckIn: true); // Check-in
            }
          : checkOutTime == null
              ? () async {
                  await _fetchLocation();
                  await _submitAttendance(isCheckIn: false); // Check-out
                }
              : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        backgroundColor:
            checkInTime == null ? Colors.green : Colors.red, // Button color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: checkInTime == null
          ? const Icon(Icons.login, size: 24)
          : const Icon(Icons.logout, size: 24),
      label: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(checkInTime == null ? 'Check In' : 'Check Out',
              style: const TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custodian Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (checkInTime != null)
              Card(
                color: Colors.green.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.login, size: 40, color: Colors.green),
                  title: const Text('Check-In Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Time: ${checkInTime.toString()}\nLocation: ($checkInLat, $checkInLong)'),
                ),
              ),
            if (checkInTime != null) const SizedBox(height: 10),
            if (checkOutTime == null && checkInTime != null)
              Card(
                color: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.logout, size: 40, color: Colors.red),
                  title: const Text('Check-Out Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: const Text("No check-out data available"),
                ),
              ),
            const SizedBox(height: 30),
            _buildAttendanceButton(),
          ],
        ),
      ),
    );
  }
}
