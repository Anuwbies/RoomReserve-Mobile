import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Access navigatorKey
import '../Pages/Notifications_Page.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  /// Define a high importance channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.max,
    playSound: true,
  );

  /// Initialize FCM: Request permission and setup listeners
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool('fcm_enabled') ?? true;

    // If notifications are disabled by the user, don't initialize listeners or request permission
    if (!isEnabled) {
      debugPrint('FCM initialization skipped: Notifications disabled in settings');
      
      // Cleanup token from Firestore if it exists
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? deviceId = await _getDeviceId();
        if (deviceId != null) {
          await deleteTokenFromFirestore(user.uid, deviceId);
        }
      }
      return;
    }

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. Initialize Local Notifications for Foreground
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleMessageInteraction();
      },
    );

    // 3. Create the channel on Android
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Set Foreground Notification Presentation Options (iOS)
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Setup Interacted Message Handlers (Background/Terminated)
    await _setupInteractedMessage();

    // 6. Get and Save Token
    await _saveTokenToFirestore();

    // 7. Listen for Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(token: newToken);
    });

    // 8. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Re-check settings in case they changed while app was running
      final freshPrefs = await SharedPreferences.getInstance();
      final bool showInApp = freshPrefs.getBool('fcm_show_in_app') ?? true;
      final bool enableSound = freshPrefs.getBool('fcm_enable_sound') ?? true;
      final bool enableVibration = freshPrefs.getBool('fcm_enable_vibration') ?? true;
      final bool masterEnabled = freshPrefs.getBool('fcm_enabled') ?? true;

      if (!masterEnabled || !showInApp) return; 

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: enableSound,
              enableVibration: enableVibration,
            ),
            iOS: DarwinNotificationDetails(
              presentSound: enableSound,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });
  }

  /// Handle interaction when app is in background or terminated
  static Future<void> _setupInteractedMessage() async {
    // 1. Get Initial Message (Terminated state)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageInteraction(initialMessage);
    }

    // 2. On Message Opened App (Background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageInteraction);
  }

  /// Navigate to Notifications Page
  static void _handleMessageInteraction([RemoteMessage? message]) {
    if (message != null) {
      debugPrint("Handling interaction for message: ${message.messageId}");
    }
    
    // Navigate to Notifications Page using global key
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  /// Get the FCM token and save it to the current user's Firestore document
  static Future<void> _saveTokenToFirestore({String? token}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool('fcm_enabled') ?? true;
    
    // Get unique device ID
    String? deviceId = await _getDeviceId();
    if (deviceId == null) return;

    // If master switch is off, delete token for this device
    if (!isEnabled) {
      await deleteTokenFromFirestore(user.uid, deviceId);
      return;
    }

    String? fcmToken = token ?? await _firebaseMessaging.getToken();
    if (fcmToken == null) return;

    debugPrint("Saving FCM Token for device: $deviceId");
    try {
      // Use deviceId as the document ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(deviceId) 
          .set({
        'token': fcmToken,
        'platform': defaultTargetPlatform.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deviceId': deviceId, 
      });
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  /// Delete a specific token based on device ID
  static Future<void> deleteTokenFromFirestore(String uid, String deviceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(deviceId)
          .delete();
      debugPrint("Deleted FCM token for device: $deviceId");
    } catch (e) {
      debugPrint("Error deleting FCM token: $e");
    }
  }

  /// Helper to get a unique device identifier
  static Future<String?> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Unique ID for the physical device
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // Unique ID for the app on this device
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
    return null;
  }
}
