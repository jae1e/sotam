import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/data/place.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class Hospital extends Place {
  final String phone;
  final String type; // e.g., 병원, 의원
  final List<String> subjects; // e.g., 소아청소년과
  final List<String> _detailInfo;

  // Key = _day
  // Value format = HH:mm-HH:mm
  final Map<int, String> _operatingHoursMap;
  // 'open', 'finished', 'unknown', 'notOpenedToday'
  final HospitalOperatingStatus operatingStatus;
  // Survey count
  final int surveyCount;
  // Like count
  final int likeCount;

  // Monday: 1, ... Sunday: 7, Holiday: 8
  final int _dayToday;

  Hospital.fromMap(Map<String, dynamic> data, int dayToday)
      : phone = data['phone'] ?? '',
        type = data['type'] ?? '',
        subjects = (data['subjects'] as List?)?.cast<String>() ?? [],
        _detailInfo = (data['detailInfo'] as List?)?.cast<String>() ?? [],
        _operatingHoursMap = (data['operatingHoursMap'] as Map?)
                ?.cast<String, String>()
                .map((key, value) =>
                    MapEntry<int, String>(int.parse(key), value)) ??
            {},
        operatingStatus = HospitalOperatingStatus.values.firstWhere(
            (element) => element.name == data['operatingStatus'],
            orElse: () => HospitalOperatingStatus.unknown),
        surveyCount = data['surveyCount'] ?? 0,
        likeCount = data['likeCount'] ?? 0,
        _dayToday = dayToday,
        super(
          data['hpid'],
          data['name'],
          data['address'],
          LatLng(
            data['coordinates'][1] ?? 0.0,
            data['coordinates'][0] ?? 0.0,
          ),
        ) {
    if (subjects.isEmpty) {
      throw Exception('Subject of $name ($id) is empty');
    }
  }

  // Method to get a day's operating hours as a string
  String getOperatingHours(int day) {
    return _operatingHoursMap[day] ?? '';
  }

  // Method to get today's operating hours as a string
  String getTodayOperatingHours() {
    return getOperatingHours(_dayToday);
  }

  // A method to check if hospital info has any operating hour info
  bool hasOperatingHourInfo() {
    return _operatingHoursMap.isNotEmpty;
  }

  String getDetailInfo() {
    return _detailInfo.join('\n');
  }
}

class HospitalSearchResult {
  final int totalResultCount;
  final List<Hospital> hospitals;

  HospitalSearchResult(this.totalResultCount, this.hospitals);
}
