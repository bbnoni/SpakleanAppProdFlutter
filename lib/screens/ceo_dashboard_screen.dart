import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class CEODashboardScreen extends StatefulWidget {
  const CEODashboardScreen({super.key});

  @override
  _CEODashboardScreenState createState() => _CEODashboardScreenState();
}

class _CEODashboardScreenState extends State<CEODashboardScreen> {
  // Mock Data for users
  int totalUsers = 0;
  int totalCustodians = 0;
  int totalManagers = 0;
  int totalAdmins = 0;
  int totalCEOs = 0;

  // Mock Data for facility scores
  double totalFacilityScore = 0;
  double highestFacilityScore = 0;
  double lowestFacilityScore = 0;

  // Mock data for attendance summary
  int totalCheckInsToday = 0;
  int totalCheckOutsToday = 0;

  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _fetchDashboardData(); // Fetch data when the screen loads
  }

  // Fetch all necessary data in one function
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      // Simulate data fetching for demo purposes
      await Future.delayed(
          const Duration(seconds: 2)); // Simulate network delay

      setState(() {
        // After data is fetched, update the state
        totalUsers = 50;
        totalCustodians = 30;
        totalManagers = 10;
        totalAdmins = 5;
        totalCEOs = 1;

        totalFacilityScore = 85.5;
        highestFacilityScore = 96.2;
        lowestFacilityScore = 60.0;

        totalCheckInsToday = 40;
        totalCheckOutsToday = 35;
        _isLoading = false; // Data fetching completed
      });
    } catch (e) {
      print("Error fetching dashboard data: $e");
      setState(() {
        _isLoading = false; // In case of error, stop the loading spinner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CEO Dashboard'),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator while fetching data
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildUserRoleDistributionChart(),
                  const SizedBox(height: 20),
                  _buildFacilityScoreChart(),
                  const SizedBox(height: 20),
                  _buildAttendanceSummary(),
                  const SizedBox(height: 20),
                  _buildRecentActivities(),
                ],
              ),
            ),
    );
  }

  // Summary Cards for Users, Scores, and Attendance
  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5, // Adjust aspect ratio to prevent overflow
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        _buildSummaryCard('Total Users', totalUsers.toString(), Icons.people),
        _buildSummaryCard(
            'Facility Score', '$totalFacilityScore%', Icons.score),
        _buildSummaryCard(
            'Check-Ins Today', totalCheckInsToday.toString(), Icons.login),
        _buildSummaryCard(
            'Check-Outs Today', totalCheckOutsToday.toString(), Icons.logout),
      ],
    );
  }

  // Card Widget for summary data
  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // User Role Distribution Chart (Pie Chart)
  Widget _buildUserRoleDistributionChart() {
    List<charts.Series<UserRoleData, String>> series = [
      charts.Series(
        id: 'User Roles',
        data: [
          UserRoleData('Custodians', totalCustodians),
          UserRoleData('Managers', totalManagers),
          UserRoleData('Admins', totalAdmins),
          UserRoleData('CEOs', totalCEOs),
        ],
        domainFn: (UserRoleData role, _) => role.role,
        measureFn: (UserRoleData role, _) => role.count,
        labelAccessorFn: (UserRoleData row, _) => '${row.role}: ${row.count}',
        colorFn: (_, index) {
          final colors = [
            charts.MaterialPalette.yellow.shadeDefault,
            charts.MaterialPalette.blue.shadeDefault,
            charts.MaterialPalette.green.shadeDefault,
            charts.MaterialPalette.red.shadeDefault,
          ];
          return colors[index!];
        },
      ),
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Role Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(
                height: 200, child: charts.PieChart(series, animate: true)),
          ],
        ),
      ),
    );
  }

  // Facility Score Chart (Bar Chart)
  Widget _buildFacilityScoreChart() {
    List<charts.Series<FacilityScoreData, String>> series = [
      charts.Series(
        id: 'Facility Scores',
        data: [
          FacilityScoreData('Highest', highestFacilityScore),
          FacilityScoreData('Lowest', lowestFacilityScore),
          FacilityScoreData('Average', totalFacilityScore),
        ],
        domainFn: (FacilityScoreData score, _) => score.label,
        measureFn: (FacilityScoreData score, _) => score.score,
        colorFn: (_, index) {
          final colors = [
            charts.MaterialPalette.green.shadeDefault,
            charts.MaterialPalette.red.shadeDefault,
            charts.MaterialPalette.blue.shadeDefault,
          ];
          return colors[index!];
        },
      ),
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Facility Scores Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(
                height: 200, child: charts.BarChart(series, animate: true)),
          ],
        ),
      ),
    );
  }

  // Attendance Summary
  Widget _buildAttendanceSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Total Check-ins Today: $totalCheckInsToday'),
            Text('Total Check-outs Today: $totalCheckOutsToday'),
          ],
        ),
      ),
    );
  }

  // Recent Activities
  Widget _buildRecentActivities() {
    // Mock list of activities (replace with actual data in production)
    final List<Map<String, String>> recentActivities = [
      {'name': 'John Doe', 'activity': 'Checked in at 09:00 AM'},
      {'name': 'Jane Smith', 'activity': 'Checked out at 05:00 PM'},
      {'name': 'Robert Brown', 'activity': 'Checked in at 08:30 AM'},
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: recentActivities.map((activity) {
                return ListTile(
                  leading: const Icon(Icons.account_circle, size: 40),
                  title: Text(activity['name']!),
                  subtitle: Text(activity['activity']!),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Data model for user roles
class UserRoleData {
  final String role;
  final int count;

  UserRoleData(this.role, this.count);
}

// Data model for facility scores
class FacilityScoreData {
  final String label;
  final double score;

  FacilityScoreData(this.label, this.score);
}
