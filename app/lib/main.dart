import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/preferences.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:kids_info_app/screens/home_page.dart';
import 'package:kids_info_app/screens/intro_page.dart';
import 'package:kids_info_app/theme/style.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  AuthRepository.initialize(appKey: kakaoMapJavascriptKey);
  await initializeDateFormatting();
  await Preferences.initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase analytics: failed to initialize app');
  }

  // Firebase logging
  try {
    await FirebaseAnalytics.instance.logAppOpen();
  } catch (e) {
    print('Firebase analytics: failed to log app open');
  }

  runApp(KidsInfoApp());
}

class KidsInfoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Preferences.getInstance().getString(prefUserIdKey) == null
          ? IntroPage()
          : HomePage(),
      theme: appTheme(),
      // debugShowCheckedModeBanner: false, // Debugging label
    );
  }
}
