// services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialize notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Request permissions
    await _requestPermissions();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings for both platforms
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    print('Notification service initialized');
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        print('Notification permission denied');
      }
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // You can navigate to specific screen based on payload
  }

  // Schedule a medication reminder
  Future<void> scheduleMedicationReminder(Medication medication) async {
    try {
      await initialize();

      // Calculate notification time (you can customize this based on your needs)
      // For now, we'll set it for 8:00 AM every day during the medication course
      final now = DateTime.now();
      final notificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        8, // 8:00 AM
        0,
      );

      // If the time has passed for today, schedule for tomorrow
      tz.TZDateTime scheduledDate;
      if (notificationTime.isAfter(now)) {
        scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      } else {
        scheduledDate = tz.TZDateTime.from(
          notificationTime.add(const Duration(days: 1)),
          tz.local,
        );
      }

      // Calculate end date of medication course
      final courseEndDate = medication.createdAt
          .add(Duration(days: medication.numberOfDays));

      // Only schedule if within course duration
      if (scheduledDate.isBefore(tz.TZDateTime.from(courseEndDate, tz.local))) {
        // Android notification details
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        );

        // iOS notification details
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default.wav',
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

        // Combined notification details
        const NotificationDetails details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Schedule the notification
        await _notificationsPlugin.zonedSchedule(
          medication.id.hashCode, // Use medication ID as unique ID
          '💊 Time to take medication',
          '${medication.name} - ${medication.dosage} (${medication.numberOfTablets} tablet(s))',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
          payload: medication.id,
        );

        print('Scheduled reminder for ${medication.name} at $scheduledDate');
      }
    } catch (e) {
      print('Error scheduling medication reminder: $e');
    }
  }

  // Schedule multiple reminders for a medication (e.g., morning, afternoon, evening)
  Future<void> scheduleMultipleReminders(
    Medication medication, {
    List<TimeOfDay>? times,
  }) async {
    final defaultTimes = times ?? [
      const TimeOfDay(hour: 8, minute: 0),  // Morning
      const TimeOfDay(hour: 14, minute: 0), // Afternoon
      const TimeOfDay(hour: 20, minute: 0), // Evening
    ];

    for (int i = 0; i < defaultTimes.length; i++) {
      final time = defaultTimes[i];
      await scheduleCustomReminder(
        medication,
        hour: time.hour,
        minute: time.minute,
        reminderId: i,
      );
    }
  }

  // Schedule custom reminder at specific time
  Future<void> scheduleCustomReminder(
    Medication medication, {
    required int hour,
    required int minute,
    int reminderId = 0,
  }) async {
    try {
      await initialize();

      final now = DateTime.now();
      final notificationTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      tz.TZDateTime scheduledDate;
      if (notificationTime.isAfter(now)) {
        scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      } else {
        scheduledDate = tz.TZDateTime.from(
          notificationTime.add(const Duration(days: 1)),
          tz.local,
        );
      }

      final courseEndDate = medication.createdAt
          .add(Duration(days: medication.numberOfDays));

      if (scheduledDate.isBefore(tz.TZDateTime.from(courseEndDate, tz.local))) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Use combination of medication ID and reminder ID for unique notification ID
        final notificationId = '${medication.id}_$reminderId'.hashCode;

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          '💊 Time to take ${medication.name}',
          '${medication.dosage} - ${medication.numberOfTablets} tablet(s)',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: medication.id,
        );

        print('Scheduled reminder ${reminderId + 1} for ${medication.name}');
      }
    } catch (e) {
      print('Error scheduling custom reminder: $e');
    }
  }

  // Cancel specific medication reminder
  Future<void> cancelReminder(String medicationId, [int reminderId = 0]) async {
    final notificationId = '${medicationId}_$reminderId'.hashCode;
    await _notificationsPlugin.cancel(notificationId);
    print('Cancelled reminder for medication: $medicationId');
  }

  // Cancel all reminders for a medication
  Future<void> cancelAllRemindersForMedication(String medicationId) async {
    // You might want to store reminder IDs in a database
    // For now, cancel a range of possible IDs
    for (int i = 0; i < 10; i++) {
      await cancelReminder(medicationId, i);
    }
  }

  // Cancel all notifications
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
    print('Cancelled all reminders');
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_channel',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Check if notification permission is granted
  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true; // iOS handles permissions differently
  }

  // Request notification permission explicitly
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }
}