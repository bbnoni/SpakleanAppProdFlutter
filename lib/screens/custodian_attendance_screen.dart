import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl for date formatting

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

class _CustodianAttendanceScreenState extends State<CustodianAttendanceScreen>
    with WidgetsBindingObserver {
  DateTime? checkInTime;
  DateTime? checkOutTime;
  double? checkInLat;
  double? checkInLong;
  double? checkOutLat;
  double? checkOutLong;

  bool _isLoading = false;
  bool _isButtonDisabled = false;

  List<Map<String, dynamic>> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // To observe app lifecycle
    _fetchAttendanceStatus(); // Fetch attendance status when page loads
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  // Listen to when the app is resumed to check status again
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAttendanceStatus(); // Re-fetch attendance when user returns
    }
    super.didChangeAppLifecycleState(state);
  }

  // Fetch attendance status from DB (backend for specific user and office)
  Future<void> _fetchAttendanceStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/attendance/status?user_id=${widget.userId}&office_id=${widget.officeId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (data['check_in_time'] != null) {
            checkInTime = DateTime.parse(data['check_in_time']);
            checkInLat = data['check_in_lat'];
            checkInLong = data['check_in_long'];
            checkOutTime = data['check_out_time'] != null
                ? DateTime.parse(data['check_out_time'])
                : null;
            checkOutLat = data['check_out_lat'];
            checkOutLong = data['check_out_long'];
          } else {
            checkInTime = null; // Reset if no check-in exists
            checkOutTime = null;
          }
        });

        // Ensure the button is disabled after checkout
        _checkIfAttendanceTakenToday();
        _fetchAttendanceHistory(); // Fetch the attendance history
      }
    } catch (e) {
      print("Error fetching attendance status: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if the user has already taken attendance today
  void _checkIfAttendanceTakenToday() {
    final now = DateTime.now();

    if (checkInTime != null &&
        checkInTime!.year == now.year &&
        checkInTime!.month == now.month &&
        checkInTime!.day == now.day) {
      _isButtonDisabled = checkOutTime != null;
    } else {
      setState(() {
        checkInTime = null;
        checkOutTime = null;
        _isButtonDisabled = false;
      });
    }
  }

  // Fetch attendance history from the backend
  Future<void> _fetchAttendanceHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/attendance/history?user_id=${widget.userId}&office_id=${widget.officeId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Set the attendance history in reverse order to show latest first
        setState(() {
          _attendanceHistory = List<Map<String, dynamic>>.from(data['history'])
              .reversed
              .toList();
        });
      } else {
        print("Failed to load attendance history.");
      }
    } catch (e) {
      print("Error fetching attendance history: $e");
    }
  }

  // Fetch location from API
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
          _isButtonDisabled = true; // Disable button after check-out
        }
        _fetchAttendanceHistory(); // Reload the attendance history after submitting
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

  // Format DateTime using intl package
  String _formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  // Display the attendance history
  Widget _buildAttendanceHistory() {
    if (_attendanceHistory.isEmpty) {
      return const Text("No attendance history available.");
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _attendanceHistory.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final record = _attendanceHistory[index];
        return ListTile(
          title: Text(
              'Check-In: ${_formatDateTime(DateTime.parse(record['check_in_time']))} - '
              'Check-Out: ${record['check_out_time'] != null ? _formatDateTime(DateTime.parse(record['check_out_time'])) : "Not checked out"}'),
          subtitle: Text(
              'Location: Check-In (${record['check_in_lat']}, ${record['check_in_long']})\n'
              'Check-Out (${record['check_out_lat'] ?? "N/A"}, ${record['check_out_long'] ?? "N/A"})'),
        );
      },
    );
  }

  Widget _buildAttendanceButton() {
    return ElevatedButton.icon(
      onPressed: (_isButtonDisabled)
          ? null
          : checkInTime == null
              ? () async {
                  await _fetchLocation(); // Fetch location before check-in
                  await _submitAttendance(isCheckIn: true); // Check-in
                }
              : checkOutTime == null
                  ? () async {
                      await _fetchLocation(); // Fetch location before check-out
                      await _submitAttendance(isCheckIn: false); // Check-out
                    }
                  : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        backgroundColor: _isButtonDisabled
            ? Colors.grey
            : (checkInTime == null ? Colors.green : Colors.red), // Button color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: _isButtonDisabled
          ? const Icon(Icons.check, size: 24)
          : checkInTime == null
              ? const Icon(Icons.login, size: 24)
              : const Icon(Icons.logout, size: 24),
      label: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              _isButtonDisabled
                  ? 'Checked Out'
                  : checkInTime == null
                      ? 'Check In'
                      : 'Check Out',
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
                  leading:
                      const Icon(Icons.login, size: 40, color: Colors.green),
                  title: const Text('Check-In Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Time: ${_formatDateTime(checkInTime!)}\nLocation: ($checkInLat, $checkInLong)'),
                ),
              ),
            if (checkInTime != null) const SizedBox(height: 10),
            if (checkOutTime != null)
              Card(
                color: Colors.red.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  leading:
                      const Icon(Icons.logout, size: 40, color: Colors.red),
                  title: const Text('Check-Out Status',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: checkOutTime != null
                      ? Text(
                          'Time: ${_formatDateTime(checkOutTime!)}\nLocation: ($checkOutLat, $checkOutLong)')
                      : const Text("No check-out data available"),
                ),
              ),
            const SizedBox(height: 30),
            _buildAttendanceButton(),
            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const Text("Attendance History",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 10),
            Expanded(child: _buildAttendanceHistory()),
          ],
        ),
      ),
    );
  }
}
