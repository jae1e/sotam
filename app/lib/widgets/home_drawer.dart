import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/helpers/info_helper.dart';
import 'package:kids_info_app/helpers/toast_helper.dart';
import 'package:kids_info_app/screens/announcement_page.dart';
import 'package:kids_info_app/screens/info_page.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  Widget getNewBadge(Future<bool> futureFunction) {
    return FutureBuilder<bool>(
      future: futureFunction,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data) {
          return const SizedBox();
        } else {
          return Row(
            children: [
              const SizedBox(
                width: 10,
              ),
              Container(
                width: homeDrawerNewBadgeSize,
                height: homeDrawerNewBadgeSize,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange,
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      fontSize: homeDrawerNewBadgeSize / 2,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: homeDrawerWidth,
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
              decoration: BoxDecoration(
                color: appTheme().primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/kids_search_icon_green_cropped_256.png',
                    width: homeDrawerHeaderIconSize,
                    height: homeDrawerHeaderIconSize,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    '소아과탐색기',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: homeDrawerHeaderFontSize),
                  )
                ],
              )),
          ListTile(
            title: Row(
              children: [
                const Icon(Icons.notifications_outlined),
                const SizedBox(
                  width: homeDrawerIconRightMargin,
                ),
                const Text('소식'),
                getNewBadge(isAnnouncementPageUpdated()),
              ],
            ),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AnnouncementPage()));
            },
          ),
          ListTile(
            title: const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(
                  width: homeDrawerIconRightMargin,
                ),
                Text('앱 정보'),
              ],
            ),
            onTap: () {
              Navigator.push(context,
                      MaterialPageRoute(builder: (context) => InfoPage()))
                  .then((_) => setState(() {}));
            },
          ),
          ListTile(
            title: const Row(
              children: [
                Icon(Icons.rate_review_outlined),
                SizedBox(
                  width: homeDrawerIconRightMargin,
                ),
                Text('앱 평가하기'),
              ],
            ),
            onTap: () async {
              final InAppReview inAppReview = InAppReview.instance;
              inAppReview.openStoreListing(appStoreId: appStoreId);
            },
          ),
          ListTile(
            title: const Row(
              children: [
                Icon(Icons.share_outlined),
                SizedBox(
                  width: homeDrawerIconRightMargin,
                ),
                Text('앱 공유하기 (링크 복사)'),
              ],
            ),
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: marketingUrl));
              showToast('앱 소개 링크가 복사되었습니다.\n주변 분들과 많은 공유 부탁드립니다.');
            },
          ),
        ],
      ),
    );
  }
}
