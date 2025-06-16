import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/info.dart';
import 'package:kids_info_app/data/preferences.dart';
import 'package:kids_info_app/helpers/info_helper.dart';
import 'package:kids_info_app/theme/style.dart';

class AnnouncementPage extends StatelessWidget {
  AnnouncementPage({super.key}) {
    // Update last announcement page read timestamp for app icon badge
    var prefs = Preferences.getInstance();
    prefs.setString(prefLastAnnouncementPageReadKey,
        DateFormat(timestampFormat).format(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소아과탐색기 소식'),
        leading: BackButton(onPressed: () {
          Navigator.of(context).pop();
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: FutureBuilder<List<Announcement>>(
            future: getAnnouncementList(),
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
              } else if (snapshot.data.isEmpty) {
                return const Center(
                  child: Text(
                    '등록된 공지사항이 없습니다.',
                    style: TextStyle(fontSize: 15),
                  ),
                );
              } else {
                List<Announcement> announcements = snapshot.data;
                return Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return ListTile(
                        title: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                announcement.title,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: appTheme().primaryColorDark),
                              ),
                            ),
                            SizedBox(
                                width: infoAnnouncementDateWidth,
                                child: FittedBox(
                                  child: Text(
                                    announcement.timestamp
                                        .split(' ')[0], // Date only
                                    style: TextStyle(
                                        color: appTheme().hintColor),
                                    textAlign: TextAlign.right,
                                  ),
                                ))
                          ],
                        ),
                        subtitle: Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 5),
                          child: Text(announcement.content),
                        ),
                        textColor: Colors.black,
                      );
                    },
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
