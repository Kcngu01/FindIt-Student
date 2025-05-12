import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../widgets/custom_bottom_nav.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final int _selectedIndex = 3; // Notification tab index
  
  @override
  void initState() {
    super.initState();
    // Load notifications when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              // Only show the mark all as read button if there are unread notifications
              if (provider.hasUnread) {
                return TextButton.icon(
                  onPressed: () => provider.markAllAsRead(),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark All as Read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          // Group notifications by date
          final notificationsByDate = _groupNotificationsByDate(provider.notifications);
          
          return RefreshIndicator(
            onRefresh: () => provider.loadNotifications(),
            child: ListView.builder(
              itemCount: notificationsByDate.length,
              itemBuilder: (context, index) {
                final dateGroup = notificationsByDate[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        dateGroup.dateLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    // Notifications for this date
                    ...dateGroup.notifications.map((notification) => 
                      NotificationTile(
                        notification: notification,
                        onTap: () {
                          // Mark as read when tapped
                          if (notification.status == 'unread') {
                            provider.markAsRead(notification.id);
                          }
                          
                          // Handle notification tap - can add navigation based on type or data if needed
                        },
                      )
                    ).toList(),
                    // Add a divider after each group except the last one
                    if (index < notificationsByDate.length - 1)
                      const Divider(height: 32, thickness: 1),
                  ],
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index != _selectedIndex) {
            // Navigate to other screens based on index
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/my_items');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/add_item');
            } else if (index == 4) {
              Navigator.pushReplacementNamed(context, '/more');
            }
          }
        },
      ),
    );
  }
  
  // Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when there\'s something new',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
  
  // Helper method to group notifications by date
  List<NotificationDateGroup> _groupNotificationsByDate(List<StudentNotification> notifications) {
    final Map<String, List<StudentNotification>> groups = {};
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    for (final notification in notifications) {
      final date = notification.createdAt;
      String dateKey;
      String dateLabel;
      
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        dateKey = 'today';
        dateLabel = 'Today';
      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        dateKey = 'yesterday';
        dateLabel = 'Yesterday';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        // Within the last week
        dateKey = 'week-${date.year}-${date.month}-${date.day}';
        dateLabel = DateFormat('EEEE').format(date); // Day name
      } else if (date.year == today.year) {
        // This year
        dateKey = 'month-${date.year}-${date.month}-${date.day}';
        dateLabel = DateFormat('MMM d').format(date); // Month and day
      } else {
        // Previous years
        dateKey = 'year-${date.year}-${date.month}-${date.day}';
        dateLabel = DateFormat('MMM d, yyyy').format(date); // Full date
      }
      
      groups.putIfAbsent(dateKey, () => []);
      groups[dateKey]!.add(notification);
      
      // Store the date label with the first notification in each group
      groups[dateKey]!.first = groups[dateKey]!.first; // Just to avoid IDE warnings
    }
    
    // Convert to list and sort by date (newest first)
    final result = groups.entries.map((entry) {
      return NotificationDateGroup(
        dateKey: entry.key,
        dateLabel: _getDateLabel(entry.key),
        notifications: entry.value,
      );
    }).toList();
    
    // Sort groups - today, yesterday, this week, etc.
    result.sort((a, b) {
      if (a.dateKey.startsWith('today')) return -1;
      if (b.dateKey.startsWith('today')) return 1;
      if (a.dateKey.startsWith('yesterday')) return -1;
      if (b.dateKey.startsWith('yesterday')) return 1;
      if (a.dateKey.startsWith('week') && !b.dateKey.startsWith('week')) return -1;
      if (!a.dateKey.startsWith('week') && b.dateKey.startsWith('week')) return 1;
      
      // For same category, sort by the date of first notification (newer first)
      return b.notifications.first.createdAt.compareTo(a.notifications.first.createdAt);
    });
    
    return result;
  }
  
  // Helper method to get the date label for a group
  String _getDateLabel(String dateKey) {
    if (dateKey == 'today') return 'Today';
    if (dateKey == 'yesterday') return 'Yesterday';
    
    // Extract date components for other formats
    final components = dateKey.split('-');
    if (components.length < 4) return dateKey; // Error case
    
    final year = int.parse(components[1]);
    final month = int.parse(components[2]);
    final day = int.parse(components[3]);
    final date = DateTime(year, month, day);
    
    if (dateKey.startsWith('week')) {
      return DateFormat('EEEE').format(date); // Day name
    } else if (dateKey.startsWith('month')) {
      return DateFormat('MMMM d').format(date); // Month and day
    } else {
      return DateFormat('MMMM d, yyyy').format(date); // Full date
    }
  }
}

// Helper class to group notifications by date
class NotificationDateGroup {
  final String dateKey;
  final String dateLabel;
  final List<StudentNotification> notifications;
  
  NotificationDateGroup({
    required this.dateKey,
    required this.dateLabel,
    required this.notifications,
  });
}

class NotificationTile extends StatelessWidget {
  final StudentNotification notification;
  final VoidCallback onTap;
  
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final isUnread = notification.status == 'unread';
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(notification.createdAt);
    
    // Determine icon and color based on notification type
    IconData notificationIcon = Icons.notifications;
    Color avatarColor = Theme.of(context).primaryColor;
    Color? tileBgColor = isUnread ? Colors.blue.shade50 : null;
    
    // Change icon and color based on notification type
    if (notification.type != null) {
      switch (notification.type) {
        case 'claim_update':
          notificationIcon = Icons.assignment;
          avatarColor = Colors.orange;
          tileBgColor = isUnread ? Colors.orange.shade50 : null;
          break;
        case 'item_found':
          notificationIcon = Icons.check_circle;
          avatarColor = Colors.green;
          tileBgColor = isUnread ? Colors.green.shade50 : null;
          break;
        case 'item_claimed':
          notificationIcon = Icons.backpack;
          avatarColor = Colors.purple;
          tileBgColor = isUnread ? Colors.purple.shade50 : null;
          break;
        case 'system':
          notificationIcon = Icons.info;
          avatarColor = Colors.blue;
          tileBgColor = isUnread ? Colors.blue.shade50 : null;
          break;
        default:
          notificationIcon = Icons.notifications;
          avatarColor = Theme.of(context).primaryColor;
          tileBgColor = isUnread ? Colors.blue.shade50 : null;
      }
    }
    
    // Make avatar color lighter if read
    if (!isUnread) {
      avatarColor = avatarColor.withOpacity(0.7);
    }
    
    return Card(
      elevation: isUnread ? 2 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isUnread 
            ? BorderSide(color: avatarColor.withOpacity(0.5), width: 1) 
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon with badge
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: avatarColor,
                    radius: 24,
                    child: Icon(
                      notificationIcon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Notification body
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                    // Additional metadata 
                    if (notification.type != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: avatarColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            notification.type!.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: avatarColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 