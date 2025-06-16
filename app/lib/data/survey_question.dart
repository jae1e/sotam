import 'package:kids_info_app/data/enum.dart';

class SurveyQuestion {
  final SurveyQuestionType type;
  final List<String> options;
  final int maxTextLength;

  SurveyQuestion.fromMap(Map<String, dynamic> data)
      : type = SurveyQuestionType.values.firstWhere(
            (element) => element.name == data['type'],
            orElse: () => SurveyQuestionType.unknown),
        options = (data['options'] as List?)?.cast<String>() ?? [],
        maxTextLength = data['maxTextLength'] ?? 0;
}

class SurveyQuestionsResponse {
  Map<String, SurveyQuestion> questions = {};

  SurveyQuestionsResponse(this.questions);
}
