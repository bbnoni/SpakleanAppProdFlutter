import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure storage import
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';

class CheckpointScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String zoneName;
  final String officeId;
  final String
      currentUserId; // The ID of the logged-in user performing the inspection
  final String?
      doneOnBehalfUserId; // The ID of the selected user for whom the inspection is done

  const CheckpointScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.zoneName,
    required this.officeId,
    required this.currentUserId,
    required this.doneOnBehalfUserId,
  });

  @override
  _CheckpointScreenState createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  Map<String, Set<String>> selections = {};
  DateTime? _submissionTime;
  double? latitude;
  double? longitude;
  String? locationName;
  bool _isSubmitting = false;
  final _storage = const FlutterSecureStorage(); // Secure storage instance
  String? currentUserId; // Store the current user ID from secure storage

  final Map<String, List<String>> defectOptions = {
    'CEILING': ['Cobweb', 'Dust', 'Mold', 'Stains', 'None', 'N/A'],
    'WALLS': ['Cobweb', 'Dust', 'Marks', 'Mold', 'Stains', 'None', 'N/A'],
    'Common Touch Points (CTP)': ['Dust', 'Marks', 'None', 'N/A'],
    'WINDOWS': [
      'Cobweb',
      'Droppings',
      'Dust',
      'Fingerprints',
      'Water stains',
      'Mud',
      'Stains',
      'None',
      'N/A'
    ],
    'EQUIPMENT': ['Dust', 'Cobweb', 'Stains', 'Fingerprints', 'None', 'N/A'],
    'FURNITURE': [
      'Clutter',
      'Cobweb',
      'Dust',
      'Fingerprints',
      'Gums',
      'Ink marks',
      'Stains',
      'None',
      'N/A'
    ],
    'DECOR': ['Dust', 'Cobweb', 'None', 'N/A'],
    'CARPET': [
      'Clutter',
      'Droppings',
      'Dust',
      'Gums',
      'Microbes',
      'Mud',
      'Odor',
      'Sand',
      'Spills',
      'Stains',
      'Trash',
      'None',
      'N/A'
    ],
    'FLOOR': [
      'Clutter',
      'Corner Stains',
      'Droppings',
      'Dust',
      'Dirty Grout',
      'Gums',
      'Microbes',
      'Mop Marks',
      'Mold',
      'Mud',
      'Odor',
      'Sand',
      'Shoe marks',
      'Spills',
      'Trash',
      'None',
      'N/A'
    ],
    'YARD': [
      'Trash',
      'Weeds',
      'Cobweb',
      'Oil stains',
      'Debris',
      'Clutter',
      'None',
      'N/A'
    ],
    'SANITARY WARE': [
      'Stains',
      'Dust',
      'Microbes',
      'Mold',
      'Odor',
      'Spills',
      'None',
      'N/A'
    ],
  };

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selections = defectOptions.map((key, value) => MapEntry(key, <String>{}));
    _getCurrentLocation();
    _loadCurrentUserId(); // Load user ID from secure storage
  }

  Future<void> _loadCurrentUserId() async {
    currentUserId =
        await _storage.read(key: 'currentUserId') ?? widget.currentUserId;
    print("CheckpointScreen: Retrieved currentUserId: $currentUserId");
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData? locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.changeSettings(
      accuracy: LocationAccuracy.high,
    );

    locationData = await location.getLocation();

    if (mounted) {
      setState(() {
        latitude = locationData?.latitude;
        longitude = locationData?.longitude;
      });
    }
    if (latitude != null && longitude != null) {
      locationName = await reverseGeocode(latitude!, longitude!);
    }
  }

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

  Map<String, double> _calculateAreaScores() {
    Map<String, double> areaScores = {};

    selections.forEach((area, defectsSelected) {
      int totalOptions = defectOptions[area]!.length - 2;
      if (defectsSelected.contains('None')) {
        areaScores[area] = 100.0;
      } else if (defectsSelected.contains('N/A')) {
        return;
      } else {
        int defectOptionsSelected = defectsSelected.length;
        int nonDefectSelections = totalOptions - defectOptionsSelected;
        areaScores[area] = (nonDefectSelections / totalOptions) * 100;
      }
    });

    return areaScores;
  }

  String? _getIncompleteCategory() {
    for (var category in selections.keys) {
      if (selections[category]!.isEmpty) {
        return category;
      }
    }
    return null;
  }

  Future<void> _submitDataToBackend() async {
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    final incompleteCategory = _getIncompleteCategory();

    if (incompleteCategory != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please complete the $incompleteCategory category.'),
      ));

      _scrollToCategory(incompleteCategory);
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    _submissionTime = DateTime.now();
    final areaScores = _calculateAreaScores();
    double? zoneScore;
    double? facilityScore;

    try {
      final zoneScoreUrl = Uri.encodeFull(
        'https://spaklean-app-prod.onrender.com/api/zones/${widget.zoneName}/score?office_id=${widget.officeId}&user_id=${widget.currentUserId}',
      );
      final zoneScoreResponse = await http.get(Uri.parse(zoneScoreUrl));

      if (zoneScoreResponse.statusCode == 200) {
        final zoneScoreData = jsonDecode(zoneScoreResponse.body);
        if (zoneScoreData['zone_score'] != null &&
            zoneScoreData['zone_score'] != "N/A") {
          zoneScore = double.tryParse(zoneScoreData['zone_score'].toString());
        } else {
          zoneScore = null;
        }
      }

      final facilityScoreUrl = Uri.encodeFull(
        'https://spaklean-app-prod.onrender.com/api/facility/score?office_id=${widget.officeId}&user_id=${widget.currentUserId}',
      );
      final facilityScoreResponse = await http.get(Uri.parse(facilityScoreUrl));

      if (facilityScoreResponse.statusCode == 200) {
        final facilityScoreData = jsonDecode(facilityScoreResponse.body);
        if (facilityScoreData['total_facility_score'] != null) {
          facilityScore = double.tryParse(
              facilityScoreData['total_facility_score'].toString());
        }
      }
    } catch (e) {
      print("Error fetching zone or facility score: $e");
    }

    final userId = int.tryParse(widget.currentUserId) ?? 0;
    final roomId = int.tryParse(widget.roomId) ?? 0;

    if (userId == 0 || roomId == 0) {
      print("Invalid user_id or room_id");
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid user or room ID'),
      ));
      return;
    }

    final data = {
      "task_type": "Inspection",
      "latitude": latitude,
      "longitude": longitude,
      "user_id": currentUserId, // Use the current user ID from secure storage
      "done_by_user_id": currentUserId, // ID of the current user (executor)
      "done_on_behalf_of_user_id":
          widget.doneOnBehalfUserId, // User being inspected for
      "room_id": roomId.toString(),
      "zone_name": widget.zoneName,
      "area_scores": areaScores,
      "zone_score": zoneScore,
      "facility_score": facilityScore,
    };

    print("Submitting data: $data");

    try {
      final response = await http.post(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/tasks/submit'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        _showSubmissionSummary(areaScores);
      } else {
        print("Failed to submit task: ${response.body}");
      }
    } catch (e) {
      print("Error submitting task: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSubmissionSummary(Map<String, double> areaScores) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submission Summary'),
          content: Text(
            'Room: ${widget.roomName}\nSubmission Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_submissionTime!)}\nLocation: ${latitude != null && longitude != null ? 'Lat: $latitude, Long: $longitude - $locationName' : 'Location not available'}\nArea Scores:\n${areaScores.entries.map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}%').join('\n')}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToCategory(String category) {
    final targetIndex = defectOptions.keys.toList().indexOf(category);
    final targetOffset = targetIndex * 250.0;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Checkpoint: ${widget.roomName}"),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Container(
        color: Colors.lightBlue[50],
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildCategory('CEILING', defectOptions['CEILING']!),
              buildCategory('WALLS', defectOptions['WALLS']!),
              buildCategory('Common Touch Points (CTP)',
                  defectOptions['Common Touch Points (CTP)']!),
              buildCategory('WINDOWS', defectOptions['WINDOWS']!),
              buildCategory('EQUIPMENT', defectOptions['EQUIPMENT']!),
              buildCategory('FURNITURE', defectOptions['FURNITURE']!),
              buildCategory('DECOR', defectOptions['DECOR']!),
              buildCategory('FLOOR', defectOptions['FLOOR']!),
              buildCategory('CARPET', defectOptions['CARPET']!),
              buildCategory('YARD', defectOptions['YARD']!),
              buildCategory('SANITARY WARE', defectOptions['SANITARY WARE']!),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitDataToBackend,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('Submit',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCategory(String category, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: options.map((option) {
              return FilterChip(
                label: Text(option),
                selected: selections[category]?.contains(option) ?? false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selections[category]?.add(option);
                      if (option == 'None' || option == 'N/A') {
                        selections[category]!.clear();
                        selections[category]!.add(option);
                      } else {
                        selections[category]?.remove('None');
                        selections[category]?.remove('N/A');
                      }
                    } else {
                      selections[category]?.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const Divider(thickness: 2.0, color: Colors.grey),
        ],
      ),
    );
  }
}
