import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/place.dart';
import 'package:kids_info_app/helpers/toast_helper.dart';

import 'dart:convert';

import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:http/http.dart' as http;

class _KakaoQueryResult {
  int totalCount;
  int pageableCount;
  List<Map<String, dynamic>> placeData;

  _KakaoQueryResult(this.totalCount, this.pageableCount, this.placeData);
}

// Future<HospitalSearchResult> kakaoSearchPediatricsInBounds(
//     LatLngBounds bounds) async {
//   _KakaoQueryResult searchResult = await _queryKakaoPlaceWithKeyword(
//       kakaoPediatricsQuery,
//       categoryGroupCode: kakaoHospitalCategoryGroupCode,
//       bounds: bounds);
//   if (searchResult.totalCount == 0) {
//     return HospitalSearchResult(0, 0, 0, []);
//   }
//
//   List<Hospital> searchedHospitals = searchResult.placeData.map((place) {
//     List<String> splitCategoryNames = place['category_name'].split(' ');
//     double? x = double.tryParse(place['x']);
//     double? y = double.tryParse(place['y']);
//     if (x == null || y == null) {
//       throw Exception('Failed to load nearby places: location parse error');
//     }
//     // place format:
//     // { place_name, road_address_name (도로명), x (lng), y (lat), phone, place_url,
//     //   id, address_name (지번), category_group_code, category_group_name, category_name, distance }
//     return Hospital(
//         place['id'],
//         place['place_name'],
//         place['road_address_name'],
//         LatLng(y, x),
//         place['phone'],
//         splitCategoryNames, {});
//   }).toList();
//
//   // TODO: consolidate result from backend
//   return HospitalSearchResult(searchedHospitals.length, searchResult.totalCount,
//       searchedHospitals.length, searchedHospitals);
// }

Future<PlaceSearchResult> kakaoSearchGeneralPlaces(String query) async {
  if (query.isEmpty) {
    return PlaceSearchResult(0, []);
  }

  _KakaoQueryResult searchResult = await _queryKakaoPlaceWithKeyword(query);

  if (searchResult.totalCount == 0) {
    return PlaceSearchResult(0, []);
  }

  List<Place> places = searchResult.placeData.map((place) {
    double? x = double.tryParse(place['x']);
    double? y = double.tryParse(place['y']);
    if (x == null || y == null) {
      throw Exception('Failed to load nearby places: location parse error');
    }
    return Place(place['id'], place['place_name'], place['road_address_name'],
        LatLng(y, x));
  }).toList();

  return PlaceSearchResult(searchResult.totalCount, places);
}

Future<_KakaoQueryResult> _queryKakaoPlaceWithKeyword(String query,
    {String? categoryGroupCode, LatLngBounds? bounds}) async {
  String url = 'https://dapi.kakao.com/v2/local/search/keyword.json';
  url += '?query=$query&size=$kakaoResultCountPerPage';

  if (categoryGroupCode != null) {
    url += '&category_group_code=$categoryGroupCode';
  }

  if (bounds != null) {
    double swx = bounds.getSouthWest().longitude;
    double swy = bounds.getSouthWest().latitude;
    double nex = bounds.getNorthEast().longitude;
    double ney = bounds.getNorthEast().latitude;
    url += '&rect=$swx,$swy,$nex,$ney';
  }

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'KakaoAK $kakaoRestApiKey',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    print('Bad response from _queryKakaoPlaceWithKeyword ($statusCode)');
    return _KakaoQueryResult(0, 0, []);
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  Map<String, dynamic> metaData =
      Map<String, dynamic>.from(responseBody['meta']);
  int? totalCount = metaData['total_count'];
  int? pageableCount = metaData['pageable_count'];
  List<Map<String, dynamic>> placeData =
      List<Map<String, dynamic>>.from(responseBody['documents']);

  if (totalCount == null || pageableCount == null) {
    showToast('Metadata parse error');
    return _KakaoQueryResult(0, 0, []);
  }

  return _KakaoQueryResult(totalCount, pageableCount, placeData);
}
