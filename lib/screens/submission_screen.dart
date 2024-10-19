import 'package:flutter/material.dart';

class SubmissionScreen extends StatefulWidget {
  final String userId;
  final String roomId; // Room ID passed to the screen
  final Map<String, dynamic> submissionData; // Data passed to the screen

  const SubmissionScreen({
    Key? key,
    required this.userId,
    required this.roomId,
    required this.submissionData,
  }) : super(key: key);

  @override
  _SubmissionScreenState createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // You can do any additional setup or data fetching here if needed
  }

  @override
  Widget build(BuildContext context) {
    final submissionData = widget.submissionData;
    final areaScores =
        submissionData['area_scores'] ?? {}; // Area scores passed as a map

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Text('Room ID: ${widget.roomId}',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  Text('User ID: ${widget.userId}',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  Text('Task Type: ${submissionData['task_type']}',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Submission Time: ${submissionData['submission_time']}',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  Text('Room Score: ${submissionData['room_score']}',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  const Text('Area Scores:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...areaScores.entries.map((entry) {
                    final area = entry.key;
                    final score = entry.value;
                    return Text('$area: $score%',
                        style: TextStyle(fontSize: 16));
                  }).toList(),
                ],
              ),
      ),
    );
  }
}
