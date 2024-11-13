import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({super.key, required this.userId});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  final Map<int, String> _userNamesCache = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/notifications',
        ),
      );

      if (response.statusCode == 200) {
        final notifications = jsonDecode(response.body)['notifications'];

        // Fetch user names for done_by_user_id and done_on_behalf_of_user_id
        await _fetchUserNamesForNotifications(notifications);

        setState(() {
          _notifications = notifications;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load notifications')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserNamesForNotifications(
      List<dynamic> notifications) async {
    for (var notification in notifications) {
      final doneById = notification['done_by_user_id'];
      final doneOnBehalfId = notification['done_on_behalf_of_user_id'];

      // Fetch done_by_user_id name if not cached
      if (doneById != null && !_userNamesCache.containsKey(doneById)) {
        _userNamesCache[doneById] = await _fetchUserName(doneById);
      }

      // Fetch done_on_behalf_of_user_id name if not cached
      if (doneOnBehalfId != null &&
          !_userNamesCache.containsKey(doneOnBehalfId)) {
        _userNamesCache[doneOnBehalfId] = await _fetchUserName(doneOnBehalfId);
      }
    }
  }

  Future<String> _fetchUserName(int userId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/users/$userId/details',
        ),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        final fullName = '${userData['first_name']} ${userData['last_name']}';
        return fullName;
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name for userId $userId: $e');
      return 'Unknown User';
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/notifications/mark_all_as_read',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          for (var notification in _notifications) {
            // Mark only the current user's "is_read" status as true
            if (notification['done_by_user_id'] == int.parse(widget.userId)) {
              notification['is_read_by_done_by_user'] = true;
            } else if (notification['done_on_behalf_of_user_id'] ==
                int.parse(widget.userId)) {
              notification['is_read_by_done_on_behalf_user'] = true;
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notifications as read')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markAsReadForCurrentUser(int notificationId, int index) async {
    final currentUserIsDoneByUser =
        _notifications[index]['done_by_user_id'] == int.parse(widget.userId);

    try {
      final response = await http.post(
        Uri.parse(
          'https://spaklean-app-prod.onrender.com/api/users/${widget.userId}/notifications/$notificationId/mark_as_read',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "is_done_by_user": currentUserIsDoneByUser,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (currentUserIsDoneByUser) {
            _notifications[index]['is_read_by_done_by_user'] = true;
          } else {
            _notifications[index]['is_read_by_done_on_behalf_user'] = true;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark notification as read')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final currentUserIsDoneByUser =
                    notification['done_by_user_id'] == int.parse(widget.userId);
                final currentUserIsDoneOnBehalfUser =
                    notification['done_on_behalf_of_user_id'] ==
                        int.parse(widget.userId);

                final isRead = currentUserIsDoneByUser
                    ? (notification['is_read_by_done_by_user'] ?? false)
                    : currentUserIsDoneOnBehalfUser
                        ? (notification['is_read_by_done_on_behalf_user'] ??
                            false)
                        : true;

                // Retrieve the names from the cache
                final doneById = notification['done_by_user_id'];
                final doneOnBehalfId =
                    notification['done_on_behalf_of_user_id'];
                final doneByName = doneById != null
                    ? _userNamesCache[doneById]
                    : 'Unknown User';
                final doneOnBehalfName = doneOnBehalfId != null
                    ? _userNamesCache[doneOnBehalfId]
                    : 'Unknown User';

                // Construct message based on whether the notification is on behalf of someone
                String message;
                if (doneOnBehalfId != null) {
                  message =
                      '$doneByName completed a task on behalf of $doneOnBehalfName';
                } else {
                  message = notification['message'];
                }

                return ListTile(
                  title: Text(
                    message,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification['timestamp']),
                  trailing: isRead
                      ? null
                      : const Icon(Icons.circle, color: Colors.red, size: 10),
                  onTap: () {
                    if (!isRead) {
                      _markAsReadForCurrentUser(notification['id'], index);
                    }
                  },
                );
              },
            ),
    );
  }
}
