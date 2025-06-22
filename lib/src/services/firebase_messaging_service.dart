import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show AndroidFlutterLocalNotificationsPlugin, AndroidNotificationChannel;
import '../services/login_service.dart';

// To handle notifications in the background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No need to initialize Firebase here as it should already be initialized
  print("Handling a background message: ${message.messageId}");
  // We don't show UI here, just log the message
}

class FirebaseMessagingService {
  final LoginService _loginService = LoginService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // For handling notification when the app is in the background
  final Function(RemoteMessage)? onNotificationTapped;

  FirebaseMessagingService({this.onNotificationTapped});

  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Set the background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions for iOS and Android (13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('notification_icon');
    
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS local notification
      },
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> payload = jsonDecode(response.payload!);
            // Handle notification tap
            if (onNotificationTapped != null) {
              onNotificationTapped!(RemoteMessage(data: payload));
            }
          } catch (e) {
            print('Error parsing notification payload: $e');
          }
        }
      },
    );

    // Set up foreground notification handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Set up background/terminated notification handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background state via notification');
      if (onNotificationTapped != null) {
        onNotificationTapped!(message);
      }
    });

    // Check for initial message (app opened from terminated state) is now handled in main.dart
    // to ensure the app is fully initialized before navigation

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM token refreshed: $newToken');
      registerTokenWithServer();
    });
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    // Get title and body from either notification or data payload
    String? title;
    String? body;
    
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification!.title}');
      title = message.notification!.title;
      body = message.notification!.body;
    } else if (message.data.containsKey('notification_type')) {
      // Extract title and body from data payload
      if (message.data['notification_type'] == 'claim_update') {
        if (message.data['status'] == 'approved') {
          title = 'Claim Approved';
          body = 'Your claim has been approved.';
        } else if (message.data['status'] == 'rejected') {
          title = 'Claim Rejected';
          body = 'Your claim has been rejected.';
        }
      }
    }
    
    // Only show notification if we have a title
    if (title != null) {
      // Create Android notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'claim_channel', 
        'Claim Notifications',
        channelDescription: 'Notifications about claim status updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: 'notification_icon',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      // Create iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Create platform-specific notification details
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show local notification
      await _flutterLocalNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        platformDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> registerTokenWithServer() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('Failed to get FCM token');
        return;
      }

      final deviceType = Platform.isAndroid ? 'android' : 'ios';
      
      try {
        // Send token to your Laravel backend
        await _loginService.registerFcmToken(token, deviceType);
        print('FCM token registered with server');
      } catch (e) {
        print('Error registering FCM token with server: $e');
        // Don't rethrow - this allows the app to continue working even if FCM fails
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      // Don't rethrow - this allows the app to continue working even if FCM fails
    }
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Create the channel for claim notifications
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'claim_channel',
        'Claim Notifications',
        description: 'Notifications about claim status updates',
        importance: Importance.high,
        enableLights: true,
        enableVibration: true,
      );

      // Register the channel with the system
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      print('Notification channel created: ${channel.id}');
    }
  }
} 