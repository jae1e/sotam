import 'package:kids_info_app/data/enum.dart';

class SurveySummary {
  final SurveyQuestionType type;
  final List<String> options;
  final List<int> optionCounts;
  final List<String> texts;

  SurveySummary.fromMap(Map<String, dynamic> data)
      : type = SurveyQuestionType.values.firstWhere(
            (element) => element.name == data['type'],
            orElse: () => SurveyQuestionType.unknown),
        options = (data['options'] as List?)?.cast<String>() ?? [],
        optionCounts = (data['optionCounts'] as List?)?.cast<int>() ?? [],
        texts = (data['texts'] as List?)?.cast<String>() ?? [] {
    if (options.length != optionCounts.length) {
      throw Exception('Survey summary option and count do not match: $data');
    }
  }
}

class SurveySummaryResponse {
  final String hospitalId;
  final int totalCount;
  late final Map<String, SurveySummary> summaries;

  SurveySummaryResponse(this.hospitalId, this.totalCount, this.summaries);

  SurveySummaryResponse.fromMap(Map<String, dynamic> data)
      : hospitalId = data['hospitalId'],
        totalCount = data['totalCount'] {
    if (data['summaries'] == null) {
      summaries = {};
    } else {
      summaries = (data['summaries'] as Map).map((key, value) {
        return MapEntry(key, SurveySummary.fromMap(value));
      });
    }
  }
}
