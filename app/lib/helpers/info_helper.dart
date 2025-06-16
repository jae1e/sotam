import 'dart:convert';

import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/info.dart';
import 'package:http/http.dart' as http;
import 'package:kids_info_app/data/preferences.dart';

Future<Introduction> getIntroduction() async {
  Uri uri = Uri.https(backendApiHostname, '/v1/info/introduction');

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    print('Bad response from getIntroduction ($statusCode)');
    return Introduction('', '');
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  return Introduction.fromMap(responseBody);
}

Future<String> getLastDatabaseUpdate() async {
  Uri uri = Uri.https(backendApiHostname, '/v1/database/last-update');

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    throw Exception('Bad return from last database update API: $statusCode');
  }
  Map<String, dynamic> responseBody = json.decode(response.body);
  String? timestamp = responseBody['timestamp'];
  if (timestamp == null) {
    throw Exception('Failed to find result from last database update API');
  }

  return timestamp;
}

Future<List<Announcement>> getAnnouncementList() async {
  Uri url = Uri.https(backendApiHostname, '/v1/announcements');
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    print('Bad response from getAnnouncementList ($statusCode)');
    return [];
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  int? totalCount = responseBody['totalCount'];
  int? pageableCount = responseBody['pageableCount'];
  if (totalCount == null || pageableCount == null) {
    print('getAnnouncementList: Metadata parse error');
    return [];
  }
  if (totalCount == 0) {
    return [];
  }

  List<Map<String, dynamic>> documents =
      List<Map<String, dynamic>>.from(responseBody['announcements']);

  return documents.map((document) {
    return Announcement.fromMap(document);
  }).toList();
}

Future<String> _getLastInfoUpdate() async {
  Uri uri = Uri.https(backendApiHostname, '/v1/info/last-update');

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    throw Exception('Bad return from last info update API: $statusCode');
  }
  Map<String, dynamic> responseBody = json.decode(response.body);
  String? timestamp = responseBody['timestamp'];
  if (timestamp == null) {
    throw Exception('Failed to find result from last info update API');
  }

  return timestamp;
}

Future<String> _getLastAnnouncementsUpdate() async {
  Uri uri = Uri.https(backendApiHostname, '/v1/announcements/last-update');

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    throw Exception(
        'Bad return from last announcements update API: $statusCode');
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  String? timestamp = responseBody['timestamp'];
  if (timestamp == null) {
    throw Exception('Failed to find result from last announcements update API');
  }

  return timestamp;
}

Future<bool> isInfoPageUpdated() async {
  var lastInfoPageReadStr =
      Preferences.getInstance().getString(prefLastInfoPageReadKey);
  if (lastInfoPageReadStr == null) {
    return true;
  }

  var lastRead = DateTime.now();
  try {
    lastRead = DateTime.parse(lastInfoPageReadStr);
  } catch (e) {
    print('Failed to parse last info page read: $e');
  }

  var infoUpdate = lastRead;
  try {
    infoUpdate = DateTime.parse(await _getLastInfoUpdate());
  } catch (e) {
    print('Failed to get last info update: $e');
  }

  return lastRead.isBefore(infoUpdate);
}


Future<bool> isAnnouncementPageUpdated() async {
  var lastAnnouncementPageReadStr =
  Preferences.getInstance().getString(prefLastAnnouncementPageReadKey);
  if (lastAnnouncementPageReadStr == null) {
    return true;
  }

  var lastRead = DateTime.now();
  try {
    lastRead = DateTime.parse(lastAnnouncementPageReadStr);
  } catch (e) {
    print('Failed to parse last announcement page read: $e');
  }

  var announcementUpdate = lastRead;
  try {
    announcementUpdate = DateTime.parse(await _getLastAnnouncementsUpdate());
  } catch (e) {
    print('Failed to get last announcement update: $e');
  }

  return lastRead.isBefore(announcementUpdate);
}