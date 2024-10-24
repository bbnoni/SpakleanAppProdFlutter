import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart'; // Import location package

class CheckpointScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;
  final String zoneName;
  final String officeId; // Add officeId as a parameter

  const CheckpointScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.zoneName,
    required this.officeId, // Make it required
  });

  @override
  _CheckpointScreenState createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  Map<String, Set<String>> selections = {};
  DateTime? _submissionTime;
  double? latitude;
  double? longitude;

  final Map<String, List<String>> defectOptions = {
    'CEILING': ['Cobweb', 'Dust', 'Mold', 'Stains', 'None', 'N/A'],
    'WALLS': ['Cobweb', 'Dust', 'Marks', 'Mold', 'Stains', 'None', 'N/A'],
    'CTP': ['Dust', 'Marks', 'None', 'N/A'],
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
    _getCurrentLocation(); // Fetch dynamic location on init
  }

  // Use the 'location' package to get dynamic location with high accuracy
  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData? locationData;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return; // If service not enabled, return early
      }
    }

    // Check for location permission
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // If permission denied, return early
      }
    }

    // Set location accuracy to high
    location.changeSettings(
      accuracy: LocationAccuracy.high,
    );

    // Get location data
    locationData = await location.getLocation();

    // Set the location data
    setState(() {
      latitude = locationData?.latitude;
      longitude = locationData?.longitude;
    });
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
    final incompleteCategory = _getIncompleteCategory();

    if (incompleteCategory != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please complete the $incompleteCategory category.'),
      ));

      // Scroll to the incomplete category
      _scrollToCategory(incompleteCategory);
      return;
    }

    _submissionTime = DateTime.now();

    // Calculate area scores
    final areaScores = _calculateAreaScores();

    // Fetch zone score and facility score
    double? zoneScore;
    double? facilityScore;

    try {
      // Properly encode the zone name and append office ID
      final zoneScoreUrl = Uri.encodeFull(
        'https://spaklean-app-prod.onrender.com/api/zones/${widget.zoneName}/score?office_id=${widget.officeId}',
      );
      final zoneScoreResponse = await http.get(Uri.parse(zoneScoreUrl));

      if (zoneScoreResponse.statusCode == 200) {
        final zoneScoreData = jsonDecode(zoneScoreResponse.body);
        if (zoneScoreData['zone_score'] != null &&
            zoneScoreData['zone_score'] != "N/A") {
          zoneScore = double.tryParse(zoneScoreData['zone_score'].toString());
        } else {
          zoneScore = null; // If no score, set to null
        }
      }

      final facilityScoreUrl = Uri.encodeFull(
        'https://spaklean-app-prod.onrender.com/api/facility/score?office_id=${widget.officeId}',
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

    // Prepare the data to be sent
    final data = {
      "task_type": "Inspection",
      "latitude": latitude,
      "longitude": longitude,
      "user_id": widget.userId,
      "room_id": widget.roomId,
      "zone_name": widget.zoneName, // Include the zone name in the payload
      "area_scores": areaScores, // Submit calculated area scores
      "zone_score": zoneScore, // Include the fetched zone score (or null)
      "facility_score":
          facilityScore, // Include the fetched facility score (or null)
    };

    // Print the data to check
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
    }
  }

  void _showSubmissionSummary(Map<String, double> areaScores) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submission Summary'),
          content: Text(
            'Room: ${widget.roomName}\nSubmission Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_submissionTime!)}\nLocation: ${latitude != null && longitude != null ? 'Lat: $latitude, Long: $longitude' : 'Location not available'}\nArea Scores:\n${areaScores.entries.map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}%').join('\n')}',
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
    final targetOffset =
        targetIndex * 250.0; // Approximate offset for each category
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
              buildCategory('CTP', defectOptions['CTP']!),
              buildCategory('WINDOWS', defectOptions['WINDOWS']!),
              buildCategory('EQUIPMENT', defectOptions['EQUIPMENT']!),
              buildCategory('FURNITURE', defectOptions['FURNITURE']!),
              buildCategory('DECOR', defectOptions['DECOR']!),
              buildCategory('FLOOR', defectOptions['FLOOR']!),
              buildCategory('CARPET', defectOptions['CARPET']!),
              buildCategory('YARD', defectOptions['YARD']!),
              buildCategory('SANITARY WARE', defectOptions['SANITARY WARE']!),
              const SizedBox(height: 20),
              ElevatedButton(
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
          const SizedBox(height: 10),
          const Divider(thickness: 2.0, color: Colors.grey),
        ],
      ),
    );
  }
}
