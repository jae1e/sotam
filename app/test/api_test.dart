import 'package:flutter_test/flutter_test.dart';

import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/data/hospital.dart';
import 'package:kids_info_app/helpers/hospital_search_helper.dart';

void main() {
  // TestWidgetsFlutterBinding.ensureInitialized();

  group('API Tests', () {
    test('getPediatricsInBounds returns expected data', () async {
      LatLng sw = LatLng(37.45, 126.70);
      LatLng ne = LatLng(37.46, 126.71);
      LatLngBounds bounds = LatLngBounds(sw, ne);
      var searchResult = await searchHospitalsInBounds(bounds, HospitalTypeFilter.allType, HospitalStatusFilter.allStatus);

      expect(searchResult, isA<HospitalSearchResult>());
      expect(searchResult.totalResultCount, greaterThan(0));
      expect(searchResult.hospitals[0].latLng.longitude, inInclusiveRange(sw.longitude, ne.longitude));
      expect(searchResult.hospitals[0].latLng.latitude, inInclusiveRange(sw.latitude, ne.latitude));
    });

    test('getIsTodayHoliday returns expected data', () async {
      bool result = await getIsTodayHoliday();

      expect(result, isA<bool>());
    });
  });
}
