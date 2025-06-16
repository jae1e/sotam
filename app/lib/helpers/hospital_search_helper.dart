import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/data/hospital.dart';

import 'dart:convert';

import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:http/http.dart' as http;

Future<bool> getIsTodayHoliday() async {
  Uri uri = Uri.https(backendApiHostname, '/v1/holiday/today');
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    throw Exception('Bad return from holiday check API: $statusCode');
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  int? result = responseBody['response'];
  if (result == null) {
    throw Exception('Failed to find result from holiday check API');
  }

  return result == 1 ? true : false;
}

Future<HospitalSearchResult> _getHospitalSearchResult(
    LatLngBounds bounds,
    int day,
    HospitalTypeFilter typeFilter,
    HospitalStatusFilter statusFilter) async {
  var params = {
    'swlng': '${bounds.sw.longitude}',
    'swlat': '${bounds.sw.latitude}',
    'nelng': '${bounds.ne.longitude}',
    'nelat': '${bounds.ne.latitude}',
  };

  if (typeFilter == HospitalTypeFilter.pediatrics) {
    params['pedonly'] = '1';
  }

  if (statusFilter != HospitalStatusFilter.allStatus) {
    params['status'] = statusFilter.name;
  }

  String api = typeFilter == HospitalTypeFilter.moonlight
      ? '/v1/moonlights'
      : '/v1/hospitals';

  Uri url = Uri.https(backendApiHostname, api, params);
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    print('Bad response from _getHospitalSearchResult ($statusCode)');
    return HospitalSearchResult(0, []);
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  int? totalCount = responseBody['totalCount'];
  int? pageableCount = responseBody['pageableCount'];
  if (totalCount == null || pageableCount == null) {
    print('_getHospitalSearchResult: Metadata parse error');
    return HospitalSearchResult(0, []);
  }
  if (totalCount == 0) {
    return HospitalSearchResult(0, []);
  }

  List<Map<String, dynamic>> documents =
      List<Map<String, dynamic>>.from(responseBody['hospitals']);

  return HospitalSearchResult(
      totalCount,
      documents.map((document) {
        return Hospital.fromMap(document, day);
      }).toList());
}

Future<HospitalSearchResult> searchHospitalsInBounds(LatLngBounds bounds,
    HospitalTypeFilter typeFilter, HospitalStatusFilter statusFilter) async {
  // Bounds sanity check
  if (bounds.ne.latitude <= bounds.sw.latitude ||
      bounds.ne.longitude <= bounds.sw.longitude) {
    print('Invalid bounds in searchHospitalsInBounds: $bounds');
    return HospitalSearchResult(0, []);
  }

  int day = await getIsTodayHoliday() ? 8 : DateTime.now().weekday;
  return await _getHospitalSearchResult(bounds, day, typeFilter, statusFilter);
}

Future<Hospital?> getHospitalWithId(String hospitalId) async {
  int day = await getIsTodayHoliday() ? 8 : DateTime.now().weekday;

  var params = {'hospitalId': hospitalId};
  Uri uri = Uri.https(backendApiHostname, '/v1/hospital', params);

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    print('Bad response from fetchHospitalWithId ($statusCode)');
    return null;
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  int totalCount = responseBody['totalCount'] ?? 0;
  int pageableCount = responseBody['pageableCount'] ?? 0;
  if (totalCount != 1 || pageableCount != 1) {
    print('getHospitalWithId: Metadata parse error');
    return null;
  }

  List<Map<String, dynamic>> documents =
      List<Map<String, dynamic>>.from(responseBody['hospitals']);

  var result = HospitalSearchResult(
      totalCount,
      documents.map((document) {
        return Hospital.fromMap(document, day);
      }).toList());
  if (result.hospitals.length != 1) {
    print('getHospitalWithId: body parse error');
    return null;
  }

  return result.hospitals.first;
}
