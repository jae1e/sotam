import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/info.dart';
import 'package:kids_info_app/data/preferences.dart';
import 'package:kids_info_app/helpers/info_helper.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  InfoPage({super.key}) {
    // Update last info page read timestamp for app icon badge
    var prefs = Preferences.getInstance();
    prefs.setString(prefLastInfoPageReadKey,
        DateFormat(timestampFormat).format(DateTime.now()));
  }

  Widget getSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: appTheme().primaryColor,
        ),
      ),
    );
  }

  Widget getIntroductionSection() {
    return FutureBuilder<Introduction>(
      future: getIntroduction(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              '서버 오류가 발생했습니다.',
              style: TextStyle(fontSize: 15),
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else {
          Introduction intro = snapshot.data;
          // Split introduction text to make lines
          var lines = intro.text.split('\n');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getSectionTitle(intro.title),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                    children: lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(line),
                  );
                }).toList()),
              ),
            ],
          );
        }
      },
    );
  }

  Widget getDatabaseInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getSectionTitle('데이터베이스 정보'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FutureBuilder<String>(
            future: getLastDatabaseUpdate(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasError ||
                  snapshot.hasData && snapshot.data.isEmpty) {
                return const Center(
                  child: Text(
                    '서버 오류가 발생했습니다.',
                    style: TextStyle(fontSize: 15),
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '업데이트: ${snapshot.data.split(' ')[0]}', // Date only
                    style: TextStyle(color: appTheme().hintColor),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget getAppVersionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getSectionTitle('앱 버전'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    '앱 버전을 가져올 수 없습니다.',
                    style: TextStyle(fontSize: 15),
                  ),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '${snapshot.data.version}+${snapshot.data.buildNumber}',
                    style: TextStyle(color: appTheme().hintColor),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget getPrivacyInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        getSectionTitle('개인정보 처리방침'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: InkWell(
              onTap: () async {
                Uri url = Uri.parse(privacyInfoUrl);
                await launchUrl(url);
              },
              child: Text(
                '전문보기',
                style: TextStyle(
                    color: appTheme().hintColor,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소아과탐색기 정보'),
        leading: BackButton(onPressed: () {
          Navigator.of(context).pop();
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              getIntroductionSection(),
              const SizedBox(height: 20),
              getDatabaseInfoSection(),
              const SizedBox(height: 20),
              getAppVersionSection(),
              const SizedBox(height: 20),
              getPrivacyInfoSection(),
            ],
          ),
        ),
      ),
    );
  }
}
