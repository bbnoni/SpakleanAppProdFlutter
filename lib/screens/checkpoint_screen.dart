import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CheckpointScreen extends StatefulWidget {
  final String roomId; // Room ID passed from ZoneDetailScreen
  final String roomName; // Room Name passed from ZoneDetailScreen
  final String userId; // User ID for task submission

  const CheckpointScreen(
      {super.key,
      required this.roomId,
      required this.roomName,
      required this.userId});

  @override
  _CheckpointScreenState createState() => _CheckpointScreenState();
}

class _CheckpointScreenState extends State<CheckpointScreen> {
  Map<String, Set<String>> selections =
      {}; // Stores selected issues per category
  DateTime? _submissionTime; // Stores the time of submission
  double? latitude; // To store fetched latitude
  double? longitude; // To store fetched longitude

  final Map<String, List<String>> defectOptions = {
    'CEILING': ['Cobweb', 'Dust', 'Mold', 'Stains', 'None'],
    'WALLS': ['Cobweb', 'Dust', 'Marks', 'Mold', 'Stains', 'None'],
    'CTP': ['Dust', 'Marks', 'None'],
    'WINDOWS': [
      'Cobweb',
      'Droppings',
      'Dust',
      'Fingerprints',
      'Water stains',
      'Mud',
      'Stains',
      'None'
    ],
    'EQUIPMENT': ['Dust', 'Cobweb', 'Stains', 'Fingerprints', 'None'],
    'FURNITURE': [
      'Clutter',
      'Cobweb',
      'Dust',
      'Fingerprints',
      'Gums',
      'Ink marks',
      'Stains',
      'None'
    ],
    'DÉCOR': ['Dust', 'Cobweb', 'None'],
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
      'None'
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
      'None'
    ]
  };

  @override
  void initState() {
    super.initState();
    // Initialize selections for categories
    selections = {
      'CEILING': {},
      'WALLS': {},
      'CTP': {},
      'WINDOWS': {},
      'EQUIPMENT': {},
      'FURNITURE': {},
      'DÉCOR': {},
      'FLOOR': {},
      'CARPET': {},
    };
    // Fetch location on screen load
    _fetchLocation();
  }

  // Function to calculate the percentage score of the checklist
  double calculateScore() {
    int totalOptions = 0;
    int defectOptionsSelected = 0;

    selections.forEach((key, value) {
      totalOptions += defectOptions[key]!.length - 1; // Exclude "None" option
      if (!value.contains('None')) {
        defectOptionsSelected +=
            value.intersection(defectOptions[key]!.toSet()).length;
      }
    });

    // Calculate score based on non-defect options
    int nonDefectSelections = totalOptions - defectOptionsSelected;
    return totalOptions == 0 ? 0 : (nonDefectSelections / totalOptions) * 100;
  }

  // Function to fetch location from IP
  Future<void> _fetchLocation() async {
    try {
      final response = await http.get(Uri.parse('https://ipinfo.io/json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["loc"] != null) {
          final loc = data["loc"].split(',');
          setState(() {
            latitude = double.tryParse(loc[0]);
            longitude = double.tryParse(loc[1]);
          });
          print("Location fetched: Latitude $latitude, Longitude $longitude");
        } else {
          print("Failed to get location data.");
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception while fetching location: $e");
    }
  }

  // Function to check if at least one item is selected in every category
  bool _isChecklistComplete() {
    for (var category in selections.keys) {
      if (selections[category]!.isEmpty) {
        return false;
      }
    }
    return true;
  }

  // Function to submit task data to backend
  Future<void> _submitDataToBackend() async {
    // Check if all categories have at least one selected item
    if (!_isChecklistComplete()) {
      // Show a SnackBar if the checklist is incomplete
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item from each category.'),
        ),
      );
      return;
    }

    _submissionTime = DateTime.now(); // Capture submission time

    // Prepare the data to be sent
    final data = {
      "task_type": "Inspection", // The task type you want to save
      "latitude": latitude,
      "longitude": longitude,
      "user_id": widget.userId, // Pass userId
      "room_id": widget.roomId, // Pass roomId
    };

    try {
      final response = await http.post(
        Uri.parse('https://spaklean-app-prod.onrender.com/api/tasks/submit'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        print("Task submitted successfully.");
        // Show submission summary in a dialog
        _showSubmissionSummary();
      } else {
        print("Failed to submit task: ${response.body}");
      }
    } catch (e) {
      print("Error submitting task: $e");
    }
  }

  // Function to show a summary dialog after submission
  void _showSubmissionSummary() {
    // Calculate score
    double score = calculateScore();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submission Summary'),
          content: Text(
            'Room: ${widget.roomName}\n'
            'Submission Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(_submissionTime!)}\n'
            'Score: ${score.toStringAsFixed(2)}%\n'
            'Location: ${latitude != null && longitude != null ? 'Lat: $latitude, Long: $longitude' : 'Location not available'}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context)
                    .pop(); // Navigate back to the previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Checkpoint: ${widget.roomName}"), // Display room name
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildCategory('CEILING', defectOptions['CEILING']!),
            buildCategory('WALLS', defectOptions['WALLS']!),
            buildCategory('CTP', defectOptions['CTP']!),
            buildCategory('WINDOWS', defectOptions['WINDOWS']!),
            buildCategory('EQUIPMENT', defectOptions['EQUIPMENT']!),
            buildCategory('FURNITURE', defectOptions['FURNITURE']!),
            buildCategory('DÉCOR', defectOptions['DÉCOR']!),
            buildCategory('FLOOR', defectOptions['FLOOR']!),
            buildCategory('CARPET', defectOptions['CARPET']!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _submitDataToBackend();
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build checklist categories
  Widget buildCategory(String category, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 16.0), // Adds padding to each category
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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
                      if (option == 'None') {
                        selections[category]!.clear();
                        selections[category]!.add('None');
                      } else {
                        selections[category]?.remove('None');
                      }
                    } else {
                      selections[category]?.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10), // Space between filter chips and divider
          const Divider(
            thickness: 2.0, // Thicker divider for better visual separation
            color: Colors.grey, // Change divider color
          ),
        ],
      ),
    );
  }
}
