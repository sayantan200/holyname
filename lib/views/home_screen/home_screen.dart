import 'dart:io';
import 'dart:ui' as ui;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:holyname/Sercices/Notification_services.dart';
import 'package:holyname/views/home_screen/info_screen.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<List<dynamic>> excelData = [];
  NotificationServices services = NotificationServices();
  int currentDayIndex = 0;
  DateTime? currentSelectedDate; // Track the currently selected date

  static String _formatDate(String date) {
    try {
      DateTime dateTime = DateTime.parse(date);
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    } catch (e) {
      return date; // Return original if parsing fails
    }
  }

  @pragma('vm:entry-point')
  static void printHello() async {
    try {
      // Load Excel data in background
      final ByteData data = await rootBundle.load(
          'assets/holy names shabbat and chagim pdf doc 2025 to end 2027.xlsx');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables['Sheet1'];

      if (sheet != null) {
        final dataRows = sheet.rows;
        final excelData = dataRows
            .map((row) => row.map((cell) => cell?.value).toList())
            .where((row) =>
                row.any((cellData) => cellData != null && cellData != ''))
            .toList();

        // Find today's data
        final now = DateTime.now();
        final todayString = DateFormat('yyyy-MM-dd').format(now);

        for (int i = 1; i < excelData.length; i++) {
          final rowDate = excelData[i][3]?.toString();
          if (rowDate != null &&
              (rowDate == todayString || rowDate.startsWith(todayString))) {
            final row = excelData[i];
            final holyNames = row[2]?.toString() ?? '';
            final holidayHebrew = row[9]?.toString() ?? '';

            final dayHebrew = row[0]?.toString() ?? '';
            final monthHebrew = row[1]?.toString() ?? '';

            String title = _formatDate(rowDate);
            String body = "$dayHebrew $monthHebrew\n\n$holyNames";
            if (holidayHebrew.isNotEmpty) {
              body += "\n\n$holidayHebrew";
            }

            // Send notification
            final notificationService = NotificationServices();
            await notificationService.initNotification();
            await notificationService.showSimpleNotification(
              title: title,
              body: body,
            );
            break;
          }
        }
      }
    } catch (e) {
      // Fallback notification
      final now = DateTime.now();
      final todayFormatted = DateFormat('MMMM dd, yyyy').format(now);
      final notificationService = NotificationServices();
      await notificationService.initNotification();
      await notificationService.showSimpleNotification(
        title: todayFormatted,
        body: 'Check the app for today\'s holy names and blessings',
      );
    }
  }

  final int helloAlarmID = 0;
  @override
  void initState() {
    super.initState();
    _setupPlatformSpecificNotifications();
    loadExcelData().then((value) async {
      // Simple notification setup
    });
  }

  void _setupPlatformSpecificNotifications() async {
    await NotificationServices().requestNotificationPermission(context);
    await NotificationServices().initNotification();

    if (Platform.isAndroid) {
      // Android: Use AndroidAlarmManager for background notifications
      AndroidAlarmManager.periodic(
        const Duration(days: 1), // Every 24 hours
        777,
        printHello,
        allowWhileIdle: true,
        exact: true,
        wakeup: true,
        startAt: _getNext7AM(),
        rescheduleOnReboot: true,
      );
    } else if (Platform.isIOS) {
      // iOS: Use local notifications with scheduled approach
      await _setupIOSNotifications();
    }
  }

  Future<void> _setupIOSNotifications() async {
    // Cancel any existing notifications
    await NotificationServices().cancelAllIOSNotifications();

    // iOS limitation: Only schedule next 30 days (iOS allows max 64 notifications)
    // Schedule notifications for the next 30 days at 7 AM
    for (int i = 0; i < 30; i++) {
      final notificationTime = DateTime.now().add(Duration(days: i));
      final scheduledDateTime = DateTime(
        notificationTime.year,
        notificationTime.month,
        notificationTime.day,
        7, // 7 AM
        0,
      );

      if (scheduledDateTime.isAfter(DateTime.now())) {
        await _scheduleIOSNotificationForDate(
            scheduledDateTime, i + 1000); // Use IDs starting from 1000
      }
    }
  }

  Future<void> _scheduleIOSNotificationForDate(DateTime date, int id) async {
    tz.initializeTimeZones();

    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final tz.TZDateTime scheduledDateTime = tz.TZDateTime.from(date, tz.local);

    // Load Excel data to get the actual content for this date
    String title = DateFormat('MMMM dd, yyyy').format(date);
    String body = 'Check the app for today\'s holy names and blessings';

    try {
      final ByteData data = await rootBundle.load(
          'assets/holy names shabbat and chagim pdf doc 2025 to end 2027.xlsx');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables['Sheet1'];

      if (sheet != null) {
        final dataRows = sheet.rows;
        final excelData = dataRows
            .map((row) => row.map((cell) => cell?.value).toList())
            .where((row) =>
                row.any((cellData) => cellData != null && cellData != ''))
            .toList();

        // Find data for this specific date
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        for (int i = 1; i < excelData.length; i++) {
          final rowDate = excelData[i][3]?.toString();
          if (rowDate != null &&
              (rowDate == dateString || rowDate.startsWith(dateString))) {
            final row = excelData[i];
            final holyNames = row[2]?.toString() ?? '';
            final holidayHebrew = row[9]?.toString() ?? '';
            final dayHebrew = row[0]?.toString() ?? '';
            final monthHebrew = row[1]?.toString() ?? '';

            title = _formatDate(rowDate);
            body = "$dayHebrew $monthHebrew\\n\\n$holyNames";
            if (holidayHebrew.isNotEmpty) {
              body += "\\n\\n$holidayHebrew";
            }
            break;
          }
        }
      }
    } catch (e) {
      // Use default content if Excel loading fails
    }

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      categoryIdentifier: 'holy_names_category',
      threadIdentifier: 'holy_names_thread',
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails platformChannelSpecifics =
        const NotificationDetails(iOS: iosDetails);

    await NotificationServices().notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDateTime,
          platformChannelSpecifics,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
  }

  Future getNotification() async {
    DateTime now = DateTime.now();

    final matchingRows = excelData.where((row) {
      final cellValue = row[3]; // Date column
      final parsedDate = DateTime.tryParse(cellValue.toString());

      if (parsedDate != null) {
        final rowDate =
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        return isSameDay(rowDate, now);
      }
      return false;
    }).toList();

    if (matchingRows.isNotEmpty) {
      // Display relevant information for today's date
      final row = matchingRows[0];

      // C: Holy Names Hebrew (Column 2)
      final holyNames = row[2] != null ? row[2].toString() : '';

      // D: Date (Column 3) - Reference cell
      final referenceDate = '${row[3]}';

      // K: Holiday Hebrew (Column 9) - when applicable
      final holidayHebrew = row[9] != null && row[9].toString().isNotEmpty
          ? row[9].toString()
          : '';

      // Get Hebrew day and month
      final dayHebrew = row[0] != null ? row[0].toString() : '';
      final monthHebrew = row[1] != null ? row[1].toString() : '';

      // Format notification as: A, B, C, K (when applicable)
      String notificationTitle = dateConvert(referenceDate);
      String notificationBody = "$dayHebrew $monthHebrew\n\n$holyNames";
      if (holidayHebrew.isNotEmpty) {
        notificationBody += "\n\n$holidayHebrew";
      }

      // Use simple notification for all cases
      final notificationService = NotificationServices();
      await notificationService.initNotification();
      await notificationService.showSimpleNotification(
        title: notificationTitle,
        body: notificationBody,
      );
    }
  }

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String dateConvert(String date) {
    String dateTimeString = date;

    DateTime dateTime = DateTime.parse(dateTimeString);

    String formattedDate = DateFormat('MMMM dd, yyyy').format(dateTime);
    return formattedDate;
  }

  Future<void> loadExcelData() async {
    try {
      final ByteData data = await rootBundle.load(
          'assets/holy names shabbat and chagim pdf doc 2025 to end 2027.xlsx');

      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables['Sheet1'];
      if (sheet == null) {
        return;
      }

      final dataRows = sheet.rows;

      // Process data once and cache it
      final processedData = dataRows
          .map((row) => row.map((cell) => cell?.value).toList())
          .where((row) =>
              row.any((cellData) => cellData != null && cellData != ''))
          .toList();

      setState(() {
        excelData = processedData;
      });

      if (excelData.isNotEmpty) {
        _navigateToToday();
        _setupDailyNotifications();
      }
    } catch (e) {
      // Silent error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        leadingWidth: 100,
        leading: const Center(
            child: Text(
          "Holy Names",
          style: TextStyle(color: Colors.white, fontSize: 16),
        )),
        centerTitle: true,
        title: Image.asset(
          "assets/toplogo.png",
          height: 60,
          width: 100,
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InfoScreen()));
              },
              child: const Text(
                "עלינו",
                style: TextStyle(color: Colors.white, fontSize: 25),
              )),
          // IconButton(onPressed: (){
          //   Navigator.push(context, MaterialPageRoute(builder: (context) => InfoScreen()));
          // }, icon: const Icon(Icons.info_outline, color: Colors.white,))
        ],
      ),
      body: excelData.isNotEmpty
          ? _buildCardView()
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildCardView() {
    if (excelData.isEmpty || currentDayIndex >= excelData.length - 1) {
      return const Center(child: Text('No data available'));
    }

    final currentRow = excelData[currentDayIndex + 1]; // Skip header row
    final dayHebrew = currentRow[0]?.toString() ?? '';
    final monthHebrew = currentRow[1]?.toString() ?? '';
    final holyNames = currentRow[2]?.toString() ?? '';
    final date = currentRow[3]?.toString() ?? '';
    final holidayHebrew = currentRow[9]?.toString() ?? '';

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.all(20),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hebrew Date
                      Text(
                        '$dayHebrew $monthHebrew',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textDirection: ui.TextDirection.rtl,
                      ),
                      const SizedBox(height: 10),

                      // Gregorian Date
                      Text(
                        dateConvert(date),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Holy Names
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight:
                              400, // Maximum height for very long content
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            holyNames,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: ui.TextDirection.rtl,
                          ),
                        ),
                      ),

                      // Holiday Information (if available)
                      if (holidayHebrew.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            holidayHebrew,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: ui.TextDirection.rtl,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Navigation and Action Buttons
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              IconButton(
                onPressed: currentDayIndex > 0 ? _previousDay : null,
                icon: const Icon(Icons.arrow_back_ios),
                iconSize: 30,
                color: currentDayIndex > 0 ? Colors.blue : Colors.grey,
              ),

              // Spacer
              const SizedBox(width: 50),

              // Next Button
              IconButton(
                onPressed:
                    currentDayIndex < excelData.length - 2 ? _nextDay : null,
                icon: const Icon(Icons.arrow_forward_ios),
                iconSize: 30,
                color: currentDayIndex < excelData.length - 2
                    ? Colors.blue
                    : Colors.grey,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _viewByDate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'View By Date',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _shareCurrentDay,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // PDF Download Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final ByteData data = await rootBundle.load(
                    'assets/PDF holy names shabbat and chagim pdf doc 2025 to end 2027.pdf');
                final bytes = data.buffer.asUint8List();
                await Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) async => bytes,
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, size: 22, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'שבת וחגים להדפסה',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousDay() {
    if (currentDayIndex > 0) {
      setState(() {
        currentDayIndex--;
        _updateCurrentSelectedDate();
      });
    }
  }

  void _nextDay() {
    if (currentDayIndex < excelData.length - 2) {
      setState(() {
        currentDayIndex++;
        _updateCurrentSelectedDate();
      });
    }
  }

  void _updateCurrentSelectedDate() {
    if (excelData.isNotEmpty && currentDayIndex < excelData.length - 1) {
      final currentRow = excelData[currentDayIndex + 1];
      final dateString = currentRow[3]?.toString();
      if (dateString != null) {
        try {
          currentSelectedDate = DateTime.parse(dateString);
        } catch (e) {
          // If parsing fails, keep the current selected date
        }
      }
    }
  }

  void _viewByDate() async {
    // Use currently selected date or current date as initial date
    DateTime initialDate = currentSelectedDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff7ED7C1), // Your app color
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _navigateToSpecificDate(picked);
    }
  }

  void _shareCurrentDay() {
    if (excelData.isEmpty || currentDayIndex >= excelData.length - 1) return;

    final currentRow = excelData[currentDayIndex + 1];
    final dayHebrew = currentRow[0]?.toString() ?? '';
    final monthHebrew = currentRow[1]?.toString() ?? '';
    final holyNames = currentRow[2]?.toString() ?? '';
    final date = currentRow[3]?.toString() ?? '';

    final shareText =
        '$dayHebrew: $monthHebrew\n${dateConvert(date)}\n\n$holyNames';

    Share.share(
      shareText,
      subject: 'Holy Names - ${dateConvert(date)}',
    );
  }

  void _navigateToToday() {
    final today = DateTime.now();
    final todayString = DateFormat('yyyy-MM-dd').format(today);

    for (int i = 1; i < excelData.length; i++) {
      final rowDate = excelData[i][3]?.toString();

      if (rowDate != null) {
        // Try different date formats
        if (rowDate == todayString ||
            rowDate.startsWith(todayString) ||
            rowDate.contains(todayString)) {
          setState(() {
            currentDayIndex = i - 1; // Convert to 0-based index
          });
          return;
        }
      }
    }
    // If today's date not found, show user-friendly message
    _showNoDataDialog(today);
  }

  void _showNoDataDialog(DateTime date, {bool fromPicker = false}) {
    final formattedDate = DateFormat('MMMM dd, yyyy').format(date);
    // Determine what is currently shown so we can communicate clearly
    String? currentlyShownDateStr;
    if (excelData.isNotEmpty && currentDayIndex < excelData.length - 1) {
      final currentRow = excelData[currentDayIndex + 1];
      final shownDateRaw = currentRow[3]?.toString();
      if (shownDateRaw != null) {
        final parsed = DateTime.tryParse(shownDateRaw);
        currentlyShownDateStr = parsed != null
            ? DateFormat('MMMM dd, yyyy').format(parsed)
            : shownDateRaw;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'No Data Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fromPicker
                    ? 'No holy names data is available for the selected date:'
                    : 'No holy names data is available for today:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fromPicker
                    ? (currentlyShownDateStr != null
                        ? 'Showing previously viewed date: $currentlyShownDateStr.'
                        : 'Showing previously viewed entry.')
                    : 'The app is currently showing the first available entry in the database.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _viewByDate(); // Open date picker
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Browse Dates'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSpecificDate(DateTime selectedDate) {
    final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    for (int i = 1; i < excelData.length; i++) {
      final rowDate = excelData[i][3]?.toString();

      if (rowDate != null) {
        // Try different date formats and matching strategies
        if (rowDate == selectedDateString ||
            rowDate.startsWith(selectedDateString) ||
            rowDate.contains(selectedDateString)) {
          setState(() {
            currentDayIndex = i - 1; // Convert to 0-based index
            currentSelectedDate = selectedDate; // Store the selected date
          });
          // Navigated to selected date
          return;
        }

        // Try parsing the row date and comparing DateTime objects
        try {
          final parsedRowDate = DateTime.parse(rowDate);
          if (parsedRowDate.year == selectedDate.year &&
              parsedRowDate.month == selectedDate.month &&
              parsedRowDate.day == selectedDate.day) {
            setState(() {
              currentDayIndex = i - 1; // Convert to 0-based index
              currentSelectedDate = selectedDate; // Store the selected date
            });
            // Navigated to selected date
            return;
          }
        } catch (e) {
          // Continue to next row if parsing fails
        }
      }
    }

    // If selected date not found, show user-friendly dialog tailored for picker
    _showNoDataDialog(selectedDate, fromPicker: true);
  }

  void _setupDailyNotifications() {
    // Setup 7 AM daily notifications using AndroidAlarmManager
    AndroidAlarmManager.periodic(
      const Duration(days: 1),
      helloAlarmID,
      printHello,
      startAt: _getNext7AM(),
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  DateTime _getNext7AM() {
    final now = DateTime.now();
    var next7AM = DateTime(now.year, now.month, now.day, 7, 0);

    // If it's already past 7 AM today, schedule for tomorrow
    if (now.isAfter(next7AM)) {
      next7AM = next7AM.add(const Duration(days: 1));
    }

    return next7AM;
  }
}

class ExcelDataTable extends StatelessWidget {
  final List<List<dynamic>> data;

  const ExcelDataTable({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: DataTable(
                    columnSpacing: 30.0,
                    headingRowHeight: 60.0,
                    dataRowHeight: 120.0,
                    horizontalMargin: 20.0,
                    headingRowColor:
                        MaterialStateProperty.all(Colors.grey[100]),
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.blue.withValues(alpha: 0.1);
                        }
                        return null; // Use default value
                      },
                    ),
                    columns: getColumns(),
                    rows: getRows(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          bottom: 70,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              onPressed: () async {
                final ByteData data = await rootBundle.load(
                    'assets/PDF holy names shabbat and chagim pdf doc 2025 to end 2027.pdf');
                final bytes = data.buffer.asUint8List();
                // Save the asset's content as a PDF file

                await Printing.layoutPdf(
                  onLayout: (PdfPageFormat format) async => bytes,
                );
              },
              child: const Text(
                'שבת וחגים להדפסה',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ),
        Positioned.fill(
          bottom: 20,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
              onPressed: () async {
                final currentDate = DateTime.now();
                final matchingRows = data.where((row) {
                  final cellValue = row[
                      3]; // Changed from row[4] to row[3] - date column moved
                  // Processing cell value
                  final parsedDate = DateTime.tryParse(cellValue.toString());

                  if (parsedDate != null) {
                    final rowDate = DateTime(
                        parsedDate.year, parsedDate.month, parsedDate.day);
                    return isSameDay(rowDate, currentDate);
                  }
                  return false;
                }).toList();

                // Found matching rows

                if (matchingRows.isNotEmpty) {
                  // Display relevant information for today's date
                  final row = matchingRows[0];

                  // A: Day Hebrew (Column 0)
                  final dayHebrew = '${row[0]}';

                  // B: Month Hebrew (Column 1)
                  final monthHebrew = '${row[1]}';

                  // C: Holy Names Hebrew (Column 2)
                  final holyNames = row[2] != null ? row[2].toString() : '';

                  // D: Date (Column 3) - Reference cell
                  final referenceDate = '${row[3]}';

                  // K: Holiday Hebrew (Column 9) - when applicable
                  final holidayHebrew =
                      row[9] != null && row[9].toString().isNotEmpty
                          ? row[9].toString()
                          : '';

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          '$dayHebrew $monthHebrew',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          textDirection: ui.TextDirection.rtl,
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (holyNames.isNotEmpty)
                              Text(
                                holyNames,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                ),
                                textDirection: ui.TextDirection.rtl,
                              ),
                            if (holidayHebrew.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                holidayHebrew,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textDirection: ui.TextDirection.rtl,
                              ),
                            ],
                            const SizedBox(height: 15),
                            Text(
                              dateConvert(referenceDate),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textDirection: ui.TextDirection.rtl,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Display a message if there is no information available for today's date
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('No Information Available'),
                        content: const Text(
                            "There is no information for today's date."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: const Text(
                'שמות הצדיקים של היום',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<DataColumn> getColumns() {
    return data[0]
        .map((cellData) => DataColumn(
              label: Expanded(
                child: Text(
                  cellData.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ))
        .toList();
  }

  List<DataRow> getRows() {
    final rows = List<DataRow>.generate(
      data.length - 1,
      (index) {
        final rowData = data[index + 1].map((cellData) {
          if (cellData == null || cellData == '') {
            return Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: const Center(child: Text('')),
            );
          } else if (cellData.toString().length > 100) {
            final text = cellData.toString();
            final wrappedText = wrapText(text);
            return Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Center(
                child: Text(
                  wrappedText,
                  textDirection: ui.TextDirection.rtl,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          } else if (cellData is String &&
              cellData.contains(RegExp(r'[א-ת]'))) {
            // Hebrew text - center aligned with RTL
            return Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Center(
                child: Text(
                  cellData.toString(),
                  textDirection: ui.TextDirection.rtl,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            );
          } else {
            final parsedDate = DateTime.tryParse(cellData.toString());
            if (parsedDate != null) {
              final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Center(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            } else {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Center(
                  child: Text(
                    cellData.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            }
          }
        }).toList();

        return DataRow(
          cells: rowData
              .map((cell) => DataCell(
                    cell,
                    showEditIcon: false,
                  ))
              .toList(),
        );
      },
    );
    return rows;
  }

  String wrapText(String text) {
    final int maxLength = 80; // Reduced for better display
    if (text.length <= maxLength) {
      return text;
    } else {
      String wrappedText = '';
      String remainingText = text;

      while (remainingText.length > maxLength) {
        // Find a good break point (space or period)
        int breakPoint = maxLength;
        for (int i = maxLength; i > maxLength - 20 && i > 0; i--) {
          if (remainingText[i] == ' ' ||
              remainingText[i] == '.' ||
              remainingText[i] == ';') {
            breakPoint = i + 1;
            break;
          }
        }

        wrappedText += remainingText.substring(0, breakPoint) + '\n';
        remainingText = remainingText.substring(breakPoint);
      }
      return wrappedText + remainingText;
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String dateConvert(String date) {
    String dateTimeString = date;

    DateTime dateTime = DateTime.parse(dateTimeString);

    String formattedDate = DateFormat('MMMM-dd-yyyy').format(dateTime);
    return formattedDate;
  }
}
