import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:holyname/constants/app_constants.dart';
import 'package:holyname/views/home_screen/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz; // Import the timezone data

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();

  // Initialize platform-specific services
  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }

  // FirebaseMessaging.onBackgroundMessage(firebaseMessagesBackgroundHandler);
  // await Alarm.init();

  // final excelData = await loadExcelData();
  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> firebaseMessagesBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holy name',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(0xff7ED7C1, {
          50: Color(0xff7ED7C1),
          100: Color(0xff7ED7C1),
          200: Color(0xff7ED7C1),
          300: Color(0xff7ED7C1),
          400: Color(0xff7ED7C1),
          500: Color(0xff7ED7C1),
          600: Color(0xff7ED7C1),
          700: Color(0xff7ED7C1),
          800: Color(0xff7ED7C1),
          900: Color(0xff7ED7C1),
        }),
        primaryColor: appColor,
        appBarTheme: AppBarTheme(
          backgroundColor: appColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColor,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: appColor,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: appColor,
          primary: appColor,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}






/*void scheduleAlarm(String hebrewDate, String additionalText) async{
    final currentDate = tz.TZDateTime.now(tz.local);
    final alarmTime = tz.TZDateTime(tz.local, currentDate.year, currentDate.month, currentDate.day, 7);

    final alarmSettings = AlarmSettings(
      id: 42,
      dateTime: alarmTime,
      assetAudioPath: 'assets/ring.mp3',
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      notificationTitle: 'Hebrew Date: $hebrewDate',
      notificationBody: 'Additional Text: $additionalText',
      enableNotificationOnKill: true,
      stopOnNotificationOpen: true
    );

    await Alarm.set(alarmSettings: alarmSettings);
    await Alarm.setNotificationOnAppKillContent("Hebrew Date: $hebrewDate", 'Additional Text: $additionalText');
  }
*/