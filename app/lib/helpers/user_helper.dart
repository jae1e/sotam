import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

Future<String> getOrCreateUserId() async {
  var prefs = Preferences.getInstance();
  String? userId = prefs.getString(prefUserIdKey);

  // Use platform specific method to generate user id
  if (userId == null) {
    if (Platform.isAndroid) {
      const androidId = AndroidId();
      userId = await androidId.getId();
      if (userId != null && userId.isNotEmpty) {
        userId = '$userId-android';
      }
    } else if (Platform.isIOS) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      userId = iosInfo.identifierForVendor;
      if (userId != null && userId.isNotEmpty) {
        userId = '$userId-ios';
      }
    }
    // Generate UUID if user id is still null or empty
    if (userId == null || userId.isEmpty) {
      userId = const Uuid().v4();
      if (userId.isNotEmpty) {
        userId = '$userId-uuid';
      }
    }
    // Sanity check
    if (userId.isEmpty) {
      throw Exception('Failed to generate valid user id');
    }

    print('Generated user id: $userId');
    await prefs.setString(prefUserIdKey, userId);
  }
  
  return userId;
}

Future<int> getUserSurveyCount() async {
  String userId = await getOrCreateUserId();

  var params = {
    'userId': userId,
  };
  Uri uri = Uri.https(backendApiHostname, '/v1/user/survey/count', params);

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    throw Exception('Bad return from user survey count API: $statusCode');
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  int? count = responseBody['count'];
  if (count == null) {
    throw Exception('Failed to find result from survey count API');
  }

  return count;
}
