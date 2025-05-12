import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../config/api_config.dart';
import 'login_service.dart';

class NotificationService {
  final LoginService _loginService = LoginService();
  
  // Fetch all notifications for the current student
  Future<List<StudentNotification>> getNotifications() async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      print('Fetching notifications from: ${ApiConfig.notificationsEndpoint}');
      
      final response = await http.get(
        Uri.parse(ApiConfig.notificationsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Notification response status: ${response.statusCode}');
      print('Notification response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true && data.containsKey('notifications')) {
          final notifications = data['notifications'] as List;
          
          print('Processing ${notifications.length} notifications');
          
          try {
            // Apply additional check to each notification object before parsing
            List<StudentNotification> parsedNotifications = notifications.map((json) {
              print('Processing notification: $json');
              return StudentNotification.fromJson(json);
            }).toList();
            
            return parsedNotifications;
          } catch (e) {
            print('Error parsing notifications: $e');
            throw Exception('Error parsing notifications: $e');
          }
        } else {
          print('No notifications found in response');
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token expired or invalid');
      } else {
        throw Exception('Failed to get notifications with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getNotifications: $e');
      throw Exception('Error fetching notifications: $e');
    }
  }
  
  // Check if there are any unread notifications
  Future<bool> hasUnreadNotifications() async {
    try {
      final notifications = await getNotifications();
      return notifications.any((notification) => notification.status == 'unread');
    } catch (e) {
      print('Error checking unread notifications: $e');
      return false;
    }
  }
  
  // Mark a notification as read
  Future<bool> markAsRead(int notificationId) async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      print('Marking notification as read: $notificationId');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.notificationsEndpoint}/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Mark as read response: ${response.statusCode}, ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
  
  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final token = await _loginService.token;
    if (token == null) {
      throw Exception('No authentication token available');
    }

    try {
      print('Marking all notifications as read');
      
      final response = await http.post(
        Uri.parse(ApiConfig.markAllNotificationsReadEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Mark all as read response: ${response.statusCode}, ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }
} 