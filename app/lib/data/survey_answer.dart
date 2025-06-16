import 'package:kids_info_app/data/enum.dart';

class SurveyAnswer {
  final SurveyQuestionType type;
  String option;
  String text;

  SurveyAnswer(this.type, this.option, this.text);

  String encode() {
    return '{"type":"${type.name}","option":"$option","text":"$text"}';
  }
}

class SurveyAnswerDocument {
  final String hospitalId;
  final String userId;
  final String timestamp;
  late final Map<String, SurveyAnswer> answers;

  SurveyAnswerDocument(
      this.hospitalId, this.userId, this.timestamp, this.answers);

  SurveyAnswerDocument.fromMap(Map<String, dynamic> data)
      : hospitalId = data['hospitalId'],
        userId = data['userId'],
        timestamp = data['timestamp'],
        answers = data['answers'] == null
            ? {}
            : (data['answers'] as Map).map((key, value) {
          return MapEntry(
              key,
              SurveyAnswer(
                  SurveyQuestionType.values.firstWhere(
                          (element) => element.name == value['type'],
                      orElse: () => SurveyQuestionType.unknown),
                  value['option'] ?? "",
                  value['text'] ?? ""));
        });

  String encode() {
    List<String> answerStrings = [];
    answers.forEach((key, value) {
      answerStrings.add('"$key": ${value.encode()}');
    });

    return '{"hospitalId":"$hospitalId",'
        '"userId":"$userId",'
        '"timestamp":"$timestamp",'
        '"answers":{${answerStrings.join(',')}}}';
  }
}
