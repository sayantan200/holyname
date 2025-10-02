import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Background notification handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle background notification taps
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
}

class NotificationServices {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Configure local timezone properly
  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }
    tz.initializeTimeZones();
    if (Platform.isWindows) {
      return;
    }

    try {
      final String? timeZoneName = await FlutterTimezone.getLocalTimezone();

      // Handle outdated timezone names
      String correctedTimeZone = timeZoneName ?? 'UTC';

      // Map outdated timezone names to current ones
      switch (correctedTimeZone) {
        case 'Asia/Calcutta':
          correctedTimeZone = 'Asia/Kolkata';
          break;
        case 'Asia/Bombay':
          correctedTimeZone = 'Asia/Kolkata';
          break;
        case 'US/Eastern':
          correctedTimeZone = 'America/New_York';
          break;
        case 'US/Central':
          correctedTimeZone = 'America/Chicago';
          break;
        case 'US/Mountain':
          correctedTimeZone = 'America/Denver';
          break;
        case 'US/Pacific':
          correctedTimeZone = 'America/Los_Angeles';
          break;
        default:
          // Keep the original timezone name
          break;
      }

      tz.setLocalLocation(tz.getLocation(correctedTimeZone));
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      print('Timezone detection failed: $e, using UTC');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> initNotification() async {
    // Configure timezone first
    await _configureLocalTimeZone();
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

    // iOS notification categories for actions
    final List<DarwinNotificationCategory> darwinNotificationCategories =
        <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        'holy_names_category',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'view_action',
            'View',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),
    ];

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: false, // Request later for better UX
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: darwinNotificationCategories,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // Handle notification taps
        print('🔔 [NOTIFICATION TAP] Notification tapped:');
        print('   - ID: ${notificationResponse.id}');
        print('   - Action ID: ${notificationResponse.actionId}');
        print('   - Payload: ${notificationResponse.payload}');

        if (Platform.isIOS) {
          print(
              '🍎 [iOS NOTIFICATION TAP] iOS notification interaction detected');
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create the notification channel
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestNotificationPermission(BuildContext context) async {
    if (Platform.isIOS || Platform.isMacOS) {
      // Log current permission status (via permission_handler)
      try {
        final PermissionStatus current = await Permission.notification.status;
        print('🍎 [iOS PERMISSION] Current status before request: ' +
            current.toString());
      } catch (e) {
        print('🍎 [iOS PERMISSION] Could not read current status: ' +
            e.toString());
      }

      // Request iOS permissions properly
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Re-check permission status and log result
      try {
        final PermissionStatus after = await Permission.notification.status;
        print('🍎 [iOS PERMISSION] Status after request: ' + after.toString());
        if (!after.isGranted) {
          print(
              '🍎 [iOS PERMISSION] Not granted. Immediate notifications may not appear.');

          // Offer to open Settings so the user can enable notifications
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Enable Notifications'),
                content: const Text(
                    'Notifications are currently disabled. Please enable them in Settings to receive alerts.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        print('🍎 [iOS PERMISSION] Could not read status after request: ' +
            e.toString());
      }
    } else if (Platform.isAndroid) {
      // Request Android permissions
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();

      if (grantedNotificationPermission != true) {
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
      }
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
    print('🔔 [NOTIFICATION] Showing notification - ID: $id, Title: $title');

    if (Platform.isIOS) {
      print('🍎 [iOS NOTIFICATION] iOS-specific notification details:');
      print('   - ID: $id');
      print('   - Title: $title');
      print('   - Body: $body');
      print('   - Payload: $payLoad');
    }

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
    // Timezone is already configured in initNotification

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
    // Timezone is already configured in initNotification

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
    print(
        '⏰ [SCHEDULE] Scheduling notification - ID: $id, Time: $scheduledTime');

    // Timezone is already configured in initNotification
    final tz.TZDateTime scheduledDateTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    if (Platform.isIOS) {
      print('🍎 [iOS SCHEDULE] iOS-specific scheduled notification:');
      print('   - ID: $id');
      print('   - Title: $title');
      print('   - Body: $body');
      print('   - Scheduled Time: $scheduledDateTime');
    }

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

    // iOS-specific notification details
    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      categoryIdentifier: 'holy_names_category',
      threadIdentifier: 'holy_names_thread',
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

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

    print('✅ [SCHEDULE] Notification scheduled successfully');
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
