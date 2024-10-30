import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';

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

  String? checkInLocationName;
  String? checkOutLocationName;

  bool _isLoading = false;
  bool _isButtonDisabled = false;

  List<Map<String, dynamic>> _attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAttendanceStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAttendanceStatus();
    }
    super.didChangeAppLifecycleState(state);
  }

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
          _attendanceHistory =
              List<Map<String, dynamic>>.from(data['attendance_today'] ?? []);
          checkInTime = _attendanceHistory.isNotEmpty
              ? DateTime.parse(_attendanceHistory.last['check_in_time'])
              : null;
          checkOutTime = _attendanceHistory.isNotEmpty &&
                  _attendanceHistory.last['check_out_time'] != null
              ? DateTime.parse(_attendanceHistory.last['check_out_time'])
              : null;

          checkInLat = _attendanceHistory.isNotEmpty
              ? _attendanceHistory.last['check_in_lat']
              : null;
          checkInLong = _attendanceHistory.isNotEmpty
              ? _attendanceHistory.last['check_in_long']
              : null;
          checkOutLat = _attendanceHistory.isNotEmpty &&
                  _attendanceHistory.last['check_out_lat'] != null
              ? _attendanceHistory.last['check_out_lat']
              : null;
          checkOutLong = _attendanceHistory.isNotEmpty &&
                  _attendanceHistory.last['check_out_long'] != null
              ? _attendanceHistory.last['check_out_long']
              : null;

          if (checkInLat != null && checkInLong != null) {
            _updateLocationName(
                isCheckIn: true,
                latitude: checkInLat!,
                longitude: checkInLong!);
          }
          if (checkOutLat != null && checkOutLong != null) {
            _updateLocationName(
                isCheckIn: false,
                latitude: checkOutLat!,
                longitude: checkOutLong!);
          }

          _checkIfAttendanceTakenToday();
        });

        _fetchAttendanceHistory();
      }
    } catch (e) {
      print("Error fetching attendance status: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkIfAttendanceTakenToday() {
    // ignore: unused_local_variable
    final now = DateTime.now();
    if (checkOutTime != null) {
      setState(() {
        checkInTime = null;
        checkOutTime = null;
        _isButtonDisabled = false;
      });
    } else {
      _isButtonDisabled = false;
    }
  }

  Future<void> _fetchAttendanceHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/attendance/history?user_id=${widget.userId}&office_id=${widget.officeId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Map<String, dynamic>> historyData =
            List<Map<String, dynamic>>.from(data['history']).reversed.toList();

        // Fetch readable addresses for each history record
        for (var record in historyData) {
          if (record['check_in_lat'] != null &&
              record['check_in_long'] != null) {
            record['check_in_location'] = await reverseGeocode(
                record['check_in_lat'], record['check_in_long']);
          } else {
            record['check_in_location'] = "No address available";
          }

          if (record['check_out_lat'] != null &&
              record['check_out_long'] != null) {
            record['check_out_location'] = await reverseGeocode(
                record['check_out_lat'], record['check_out_long']);
          } else {
            record['check_out_location'] = "No address available";
          }
        }

        setState(() {
          _attendanceHistory = historyData;
        });
      } else {
        print("Failed to load attendance history.");
      }
    } catch (e) {
      print("Error fetching attendance history: $e");
    }
  }

  Future<void> _fetchLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData? locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    location.changeSettings(accuracy: LocationAccuracy.high);
    locationData = await location.getLocation();

    // ignore: unnecessary_null_comparison
    if (locationData != null) {
      setState(() {
        if (checkInTime == null) {
          checkInLat = locationData?.latitude;
          checkInLong = locationData?.longitude;
          checkInTime = DateTime.now();
          _updateLocationName(
              isCheckIn: true, latitude: checkInLat!, longitude: checkInLong!);
        } else if (checkOutTime == null) {
          checkOutLat = locationData?.latitude;
          checkOutLong = locationData?.longitude;
          checkOutTime = DateTime.now();
          _updateLocationName(
              isCheckIn: false,
              latitude: checkOutLat!,
              longitude: checkOutLong!);
        }
      });
    }
  }

  Future<void> _updateLocationName(
      {required bool isCheckIn,
      required double latitude,
      required double longitude}) async {
    String locationName = await reverseGeocode(latitude, longitude);
    setState(() {
      if (isCheckIn) {
        checkInLocationName = locationName;
      } else {
        checkOutLocationName = locationName;
      }
    });
  }

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
          setState(() {
            checkInTime = null;
            checkOutTime = null;
            _isButtonDisabled = false;
          });
        }
        _fetchAttendanceStatus();
        _fetchAttendanceHistory();
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

  String _formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

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
        final checkInAddress = record['check_in_location'] ?? "No address";
        final checkOutAddress = record['check_out_location'] ?? "No address";

        return ListTile(
          title: Text(
              'Check-In: ${_formatDateTime(DateTime.parse(record['check_in_time']))} - '
              'Check-Out: ${record['check_out_time'] != null ? _formatDateTime(DateTime.parse(record['check_out_time'])) : "Not checked out"}'),
          subtitle: Text(
              'Location:\nCheck-In (${record['check_in_lat']}, ${record['check_in_long']}) - $checkInAddress\n'
              'Check-Out (${record['check_out_lat'] ?? "N/A"}, ${record['check_out_long'] ?? "N/A"}) - $checkOutAddress'),
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
                  await _fetchLocation();
                  await _submitAttendance(isCheckIn: true);
                }
              : checkOutTime == null
                  ? () async {
                      await _fetchLocation();
                      await _submitAttendance(isCheckIn: false);
                    }
                  : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        backgroundColor: _isButtonDisabled
            ? Colors.grey
            : (checkInTime == null ? Colors.green : Colors.red),
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
                      'Time: ${_formatDateTime(checkInTime!)}\nLocation: ($checkInLat, $checkInLong) - $checkInLocationName'),
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
                          'Time: ${_formatDateTime(checkOutTime!)}\nLocation: ($checkOutLat, $checkOutLong) - $checkOutLocationName')
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

// Reverse geocoding function
Future<String> reverseGeocode(double latitude, double longitude) async {
  const apiKey = 'c5eb7405643243c68191cd30f7fcdf36';
  final url =
      'https://api.opencagedata.com/geocode/v1/json?q=$latitude+$longitude&key=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['results'] != null && data['results'].isNotEmpty) {
      return data['results'][0]['formatted'];
    } else {
      return "No location data available";
    }
  } else {
    return "Failed to fetch location";
  }
}
