import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<StudentNotification> _notifications = [];
  bool _isLoading = false;
  bool _hasUnread = false;
  String? _error;
  
  // Getters
  List<StudentNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasUnread => _hasUnread;
  String? get error => _error;
  
  // Load all notifications
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _notifications = await _notificationService.getNotifications();
      _hasUnread = _notifications.any((notification) => notification.status == 'unread');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check for unread notifications
  Future<void> checkUnreadNotifications() async {
    try {
      _hasUnread = await _notificationService.hasUnreadNotifications();
      notifyListeners();
    } catch (e) {
      print('Error checking unread notifications: $e');
    }
  }
  
  // Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _notificationService.markAsRead(notificationId);
      
      if (success) {
        // Update the notification in the local list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          // Create a new notification with updated status and readAt
          final updatedNotification = StudentNotification(
            id: notification.id,
            studentId: notification.studentId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            data: notification.data,
            status: 'read',
            readAt: DateTime.now(),
            createdAt: notification.createdAt,
            updatedAt: DateTime.now(),
          );
          
          _notifications[index] = updatedNotification;
          
          // Check if we still have any unread notifications
          _hasUnread = _notifications.any((notification) => notification.status == 'unread');
          
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      
      if (success) {
        // Update all notifications in the local list
        _notifications = _notifications.map((notification) {
          // Only update status if it's unread
          if (notification.status == 'unread') {
            return StudentNotification(
              id: notification.id,
              studentId: notification.studentId,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              data: notification.data,
              status: 'read',
              readAt: DateTime.now(),
              createdAt: notification.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return notification;
        }).toList();
        
        _hasUnread = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}