import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/screens/home_page.dart';
import 'package:kids_info_app/theme/style.dart';

class IntroPage extends StatefulWidget {
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          titleWidget: const SizedBox(),
          bodyWidget: Image.asset('assets/images/Screenshot 1.png'),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          bodyWidget: Image.asset('assets/images/Screenshot 2.png'),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          bodyWidget: Image.asset('assets/images/Screenshot 3.png'),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          bodyWidget: Image.asset('assets/images/Screenshot 4.png'),
        ),
      ],
      bodyPadding: const EdgeInsets.only(top: introTopMargin),
      showNextButton: false,
      showDoneButton: true,
      done: const Text(
        '시작하기',
        style: TextStyle(fontSize: 15),
      ),
      doneStyle: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(appTheme().primaryColor),
          foregroundColor: const MaterialStatePropertyAll(Colors.white)),
      onDone: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomePage())),
    );
  }
}
