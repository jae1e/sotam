import 'dart:convert';

import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/hospital.dart';
import 'package:kids_info_app/data/like.dart';
import 'package:http/http.dart' as http;
import 'package:kids_info_app/helpers/user_helper.dart';

Future<bool> postLike(Hospital hospital, bool like) async {
  Uri uri = Uri.https(backendApiHostname, '/v1/like');

  String userId = await getOrCreateUserId();

  LikePostRequest request = LikePostRequest(hospital.id, userId, like);

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body: request.encode(),
  );

  return response.statusCode == 200;
}

Future<int> getLikeCount(Hospital hospital) async {
  String hospitalId = hospital.id;

  var params = {
    'hospitalId': hospitalId,
  };
  Uri uri = Uri.https(backendApiHostname, '/v1/like/count', params);

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    throw Exception('Bad return from like count API: $statusCode');
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  int? count = responseBody['count'];
  if (count == null) {
    throw Exception('Failed to find result from like count API');
  }

  return count;
}

Future<bool> getLikeFound(Hospital hospital) async {
  String hospitalId = hospital.id;

  var params = {
    'hospitalId': hospitalId,
    'userId': await getOrCreateUserId(),
  };
  Uri uri = Uri.https(backendApiHostname, '/v1/like/found', params);

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    throw Exception('Bad return from like found API: $statusCode');
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  int? result = responseBody['found'];
  if (result == null) {
    throw Exception('Failed to find result from like found API');
  }

  return result == 1 ? true : false;
}
