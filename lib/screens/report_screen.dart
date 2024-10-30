import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'score_summary_screen.dart'; // Import the ScoreSummaryScreen

class ReportScreen extends StatefulWidget {
  final String userId;
  const ReportScreen({super.key, required this.userId});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  // Fetch all tasks for the user
  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/tasks'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _tasks = data['tasks'];
          print("Fetched Tasks: $_tasks");
        });
      } else {
        _showError('Failed to load tasks');
      }
    } catch (e) {
      _showError('An error occurred while fetching tasks');
      print("Error fetching tasks: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Helper method to get color for each zone
  Color _getZoneColor(String zoneName) {
    switch (zoneName) {
      case 'Low Traffic Areas (Yellow Zone)':
        return Colors.yellow[700]!;
      case 'Heavy Traffic Areas (Orange Zone)':
        return Colors.orange[700]!;
      case 'Food Service Areas (Green Zone)':
        return Colors.green[700]!;
      case 'High Microbial Areas (Red Zone)':
        return Colors.red[700]!;
      case 'Outdoors & Exteriors (Black Zone)':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  // Group tasks by zones
  Map<String, List<dynamic>> _groupTasksByZone(List<dynamic> tasks) {
    final Map<String, List<dynamic>> groupedTasks = {};
    for (var task in tasks) {
      final zoneName = task['zone_name'] ?? 'Unknown Zone';
      if (groupedTasks.containsKey(zoneName)) {
        groupedTasks[zoneName]?.add(task);
      } else {
        groupedTasks[zoneName] = [task];
      }
    }
    return groupedTasks;
  }

  // Filter tasks by selected date
  List<dynamic> _getTasksForSelectedDate() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final selectedDateFormatted = formatter.format(_selectedDate);

    return _tasks.where((task) {
      final taskDate = task['date_submitted'].substring(0, 10);
      return taskDate == selectedDateFormatted;
    }).toList();
  }

  // Build each task card
  Widget _buildTaskCard(Map<String, dynamic> task) {
    final zoneName = task['zone_name'] ?? 'N/A';

    final zoneScore = task['zone_score'] != null
        ? '${double.tryParse(task['zone_score'].toString())?.toStringAsFixed(2)}%'
        : 'N/A';

    final facilityScore = task['facility_score'] != null
        ? '${double.tryParse(task['facility_score'].toString())?.toStringAsFixed(2)}%'
        : 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Type: ${task['task_type']}',
                style: const TextStyle(
                    fontSize: 18.0, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text(
                'Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(task['date_submitted']))}'),
            Text('Room Score: ${task['room_score']?.toStringAsFixed(2)}%'),
            Text('Zone: $zoneName'),
            Text('Zone Score: $zoneScore'),
            Text('Facility Score: $facilityScore'),
            Text('Latitude: ${task['latitude']}'),
            Text('Longitude: ${task['longitude']}'),
            const SizedBox(height: 8.0),
            const Text('Area Scores:'),
            ...task['area_scores']
                .entries
                .map((entry) =>
                    Text('${entry.key}: ${entry.value.toStringAsFixed(2)}%'))
                .toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDate = _getTasksForSelectedDate();
    final groupedTasksByZone = _groupTasksByZone(tasksForSelectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ScoreSummaryScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() => _selectedDate = selectedDay);
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week', // Remove two weeks format
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && tasksForSelectedDate.isEmpty)
            const Center(child: Text('No tasks found for this date')),
          if (!_isLoading && tasksForSelectedDate.isNotEmpty)
            Expanded(
              child: ListView(
                children: groupedTasksByZone.keys.map((zone) {
                  final zoneColor = _getZoneColor(zone);
                  return ExpansionTile(
                    title: Text(zone, style: TextStyle(color: zoneColor)),
                    children: groupedTasksByZone[zone]!
                        .map((task) => _buildTaskCard(task))
                        .toList(),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
