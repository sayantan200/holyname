import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class InfoScreen extends StatefulWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Information"),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () {
                        setState(() {
                          isLoading = !isLoading;
                        });
                      },
                        child: Text(isLoading ? "English" : "עברית ",
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                          ),),),
                      IconButton(onPressed: () {
                        setState(() {
                          isLoading = !isLoading;
                        });
                      }, icon: const Icon(Icons.visibility))
                    ],
                  ),
                  isLoading ? const Text("""אפליקציה זו מוקדשת לעילוי נשמת אסתר בת יקוט ז״ל.
הסיפור הוא כזה, היינו בתקוע התארחנו אצל אחות של אישתי לשבת.
ומצאתי ספר נפלא שמות של צדיקים בבית כנסת של חב״ד - ברסלב, אלו שמות שיש לומר כל יום בשנה קראתי ממנו כמה עמודים והתאהבתי בו
ציפיתי מאוד למצוא אותו לקנות אותו ולקרוא בו כל יום.
באותו בוקר של יום ראשון אחרי השבת הגעתי לעבודתי בתל אביב ועל השולחן חיכו לי כמה ספרים שהבת של אסתר ז״ל הניחה לי על השולחן שאקח לגניזה, חלקם באמת הלכו אבל לא הספר הספר הזה, שמות של צדיקים בדיוק הספר שראיתי בשבת בבית הכנסת.
אותו אני שומר בתיק של הטלית וקורא את השמות בכל יום והבנתי בעצם שאני צריך לחלוק את זה עם העולם.
יש לי כמה מתכנתים שכותבים לי אפליקציות, ואחד מהם כתב את האפליקציה הזו שבו אתה משתמש, פניתי לחנות הספרים של ברסלב כדי לקבל את רשימת השמות וירון יותר משמח לשלוח לי את רשימת האקסל שאוכל לעבוד איתה.
האפליקצייה בה אתה משתמש היא תוצאה של המאמץ הקטן הזה,
תהנו
ושזה יהיה לעילוי נשמת אסתר בת יקוט ז״ל
""",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18
                    ),
                  textDirection: ui.TextDirection.rtl,) : const Text(
                    "This app is dedicated to Esther bat Yakut; may her soul be elevated. "
                        "The story goes like this. We were in Tekoa for Shabbat by my wife's sister, "
                        "and I found a fantastic sefer in the Chabad-Breslov shul - names of "
                        "righteous people, names to say for each day of the year. I read a few pages. "
                        "Fell in love with the book and davened and davened very hard that I would find it one day "
                        "and purchase it and use it every day. That Sunday morning, when I came to work in Tel Aviv, "
                        "it was sitting on my desk. Esther bat Yakut's daughter was cleaning out some sefarim and "
                        "wanted to give them to me to take to the genizah. Some did go, but not this one. "
                        "I keep it in my tallis bag and read the names for each day. "
                        "Then I realized I should share it with the world. On the side, "
                        "I have programmers write apps for me, so I had one develop the app you are using. "
                        "To get the names, I contacted the Breslov book store, "
                        "and Yaron was more than happy to send me the Excel to work with. "
                        "The app you are using is the result of that small effort."
                        " Enjoy, and may Esther bat Yakut's neshama have an aliya.",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18
                    ),)
                ],
              ),
            ),
          )),
    );
  }


}


//
// class ViewPdf extends StatelessWidget {
//   const ViewPdf({super.key});
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: appColor,
//       floatingActionButton: FloatingActionButton(onPressed: (){
//         _generatePdf();
//       },
//         backgroundColor: appColor,
//         child: const Icon(Icons.print),),
//         appBar: AppBar(title: const Text("PDF Download")),
//         body: SfPdfViewer.asset("assets/holy.pdf"),
//
//
//     );
//   }
//
//
//   Future _generatePdf() async {
//
//     final ByteData data = await rootBundle.load('assets/holy.pdf');
//     final bytes = data.buffer.asUint8List();
//
//     // Save the asset's content as a PDF file
//
//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => bytes,
//     );
//   }
// }
//
