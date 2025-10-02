import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationServices {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'holy_names_channel',
      'Holy Names Notifications',
      description: 'Daily holy names notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});

    // Create the notification channel
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestNotificationPermission(BuildContext context) async {
    PermissionStatus notificationPermissionStatus =
        await Permission.notification.request();

    if (notificationPermissionStatus.isGranted) {
      // Permission is granted, you can now use notifications.
    } else if (notificationPermissionStatus.isDenied) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Notification Permission Required'),
            content: const Text(
                'Please enable notification permissions in the app settings to receive updates.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            ],
          );
        },
      );
      // Permission is denied.
    } else if (notificationPermissionStatus.isPermanentlyDenied) {
      // Permission is permanently denied. Prompt user to open app settings.
    }
  }

  Future<void> openAppSetting() async {
    await openAppSettings();
  }

  Future<void> cancelAllIOSNotifications() async {
    await notificationsPlugin.cancelAll();
  }

  notificationDetails() {
    return NotificationDetails(
        android: const AndroidNotificationDetails(
          'holy_names_channel',
          'Holy Names Notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Holy Names',
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          badgeNumber: 1,
          categoryIdentifier: 'holy_names_category',
          threadIdentifier: 'holy_names_thread',
          interruptionLevel: InterruptionLevel.active,
        ));
  }

  Future showNotification(
      {int id = 0, String? title, String? body, String? payLoad}) async {
    return notificationsPlugin.show(
        id, title, body, await notificationDetails());
  }

  Future<void> scheduleDailyNotification(
      {int id = 2,
      String? title,
      String? body,
      String? payLoad,
      int hour = 7,
      int minute = 0}) async {
    tz.initializeTimeZones(); // Initialize timezones (you can call this once in your app)

    // Get the user's current timezone
    //String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    // Get the current time in the user's time zone
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Create the scheduled date time in the user's time zone
    tz.TZDateTime scheduledDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past (e.g., it's already past 7:00 AM today),
    // schedule it for the next day instead.
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    return notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDateTime,
      await notificationDetails(),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payLoad,
    );
  }

  Future<void> showImmediateZonedNotification({
    int id = 2,
    String? title,
    String? body,
    String? payLoad,
    int hour = 7,
    int minute = 0,
  }) async {
    tz.initializeTimeZones();

    // Get the user's current timezone with fallback
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      // Fallback to UTC if timezone not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Get the current time in the user's time zone
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Create the scheduled date time in the user's time zone
    tz.TZDateTime scheduledDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    // Schedule the daily repeating notification
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDateTime,
      await notificationDetails(),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payLoad,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    tz.initializeTimeZones();

    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final tz.TZDateTime scheduledDateTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'holy_names_channel',
      'Holy Names Notifications',
      channelDescription: 'Daily holy names notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDateTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'holy_names_channel',
      'Holy Names Notifications',
      channelDescription: 'Daily holy names notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: null,
        htmlFormatContentTitle: false,
        summaryText: null,
        htmlFormatSummaryText: false,
      ),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await notificationsPlugin.show(
      999, // Fixed ID to avoid duplicates
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
