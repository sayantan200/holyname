import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:holyname/views/home_screen/home_screen.dart';
import 'package:lottie/lottie.dart';

Future<List<List<dynamic>>> loadExcelData() async {
  final ByteData data = await rootBundle.load(
      'assets/holy names shabbat and chagim pdf doc 2025 to end 2027.xlsx');
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final excel = Excel.decodeBytes(bytes);

  final sheet = excel.tables['Sheet1']; // Replace 'Sheet1' with your sheet name
  final dataRows = sheet?.rows;

  return dataRows
          ?.map((row) => row.map((cell) => cell?.value).toList())
          .where((row) =>
              row.any((cellData) => cellData != null && cellData != ''))
          .toList() ??
      [];
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 2), () async {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                height: 200,
                width: 200,
                child: Lottie.asset('assets/calender.json', fit: BoxFit.cover),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
