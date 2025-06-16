import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/hospital.dart';
import 'package:kids_info_app/data/survey_answer.dart';
import 'package:kids_info_app/data/survey_question.dart';
import 'package:kids_info_app/data/survey_summary.dart';
import 'package:kids_info_app/helpers/toast_helper.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kids_info_app/helpers/user_helper.dart';
import 'package:kids_info_app/theme/style.dart';

Future<SurveyQuestionsResponse> getSurveyQuestions() async {
  Uri uri = Uri.https(backendApiHostname, '/v1/survey/questions');

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    showToast('Bad response from survey server.');
    return SurveyQuestionsResponse({});
  }

  Map<String, dynamic> responseBody = json.decode(response.body);

  Map<String, Map<String, dynamic>> documents =
      Map<String, Map<String, dynamic>>.from(responseBody['questions']);
  Map<String, SurveyQuestion> questions = documents.map((key, document) {
    return MapEntry(key, SurveyQuestion.fromMap(document));
  });

  return SurveyQuestionsResponse(questions);
}

Future<bool> submitSurveyAnswer(
    Hospital hospital, Map<String, SurveyAnswer> answers) async {
  Uri uri = Uri.https(backendApiHostname, '/v1/survey/submit');

  String userId = await getOrCreateUserId();
  String timestamp = DateFormat(timestampFormat).format(DateTime.now());
  SurveyAnswerDocument request =
      SurveyAnswerDocument(hospital.id, userId, timestamp, answers);

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body: request.encode(),
  );

  int statusCode = response.statusCode;
  if (statusCode == 201) {
    showToast('설문 응답이 등록되었습니다.');
    return true;
  } else if (statusCode == 200) {
    showToast('설문 응답이 수정되었습니다.');
    return true;
  } else {
    showToast('설문 응답 제출에 실패했습니다.');
    return false;
  }
}

Future<SurveySummaryResponse> getSurveySummary(Hospital hospital) async {
  String hospitalId = hospital.id;

  var params = {'hospitalId': hospitalId};
  Uri uri = Uri.https(backendApiHostname, '/v1/survey/summary', params);

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    print('Bad response from getSurveySummary ($statusCode)');
    return SurveySummaryResponse(hospitalId, 0, {});
  }

  Map<String, dynamic> responseBody = json.decode(response.body);
  return SurveySummaryResponse.fromMap(responseBody);
}

Future<SurveyAnswerDocument> getSurveyAnswer(Hospital hospital) async {
  String userId = await getOrCreateUserId();
  String hospitalId = hospital.id;

  var params = {'userId': userId, 'hospitalId': hospitalId};
  Uri uri = Uri.https(backendApiHostname, '/v1/survey/answer', params);

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  );

  int statusCode = response.statusCode;
  if (statusCode != 200) {
    print('Bad response from getSurveyAnswer ($statusCode)');
    return SurveyAnswerDocument(hospitalId, userId, '', {});
  }

  Map<String, dynamic> responseBody = json.decode(response.body);

  String? timestamp = responseBody['timestamp'];
  if (timestamp == null) {
    showToast('Metadata parse error');
    return SurveyAnswerDocument(hospitalId, userId, '', {});
  }

  return SurveyAnswerDocument.fromMap(responseBody);
}

String getSurveyQuestionDescription(String questionKey) {
  switch (questionKey) {
    case 'waitingSpace':
      return '진료 대기 공간 크기는 어떤가요?';
    case 'cleanliness':
      return '공간이 청결한 편인가요?';
    case 'parkingDifficulty':
      return '주차는 어떤가요?';
    case 'kindness':
      return '친절한 편인가요?';
    case 'thoroughness':
      return '진료가 꼼꼼한 편인가요?';
    case 'medicineStrength':
      return '처방약 세기는 어느 정도인가요?';
    case 'ivTreatment':
      return '영유아 수액 치료를 하나요?';
    case 'whenToVisit':
      return '언제 가기 좋은가요?';
    case 'checkupAvailable':
      return '영유아 검진을 하나요?';
    case 'checkupWaiting':
      return '검진 대기 기간은 어느 정도인가요?';
    default:
      print('Failed to convert question to string');
      return questionKey;
  }
}

String getSurveyAnswerOptionDescription(String option) {
  switch (option) {
    case 'bigSpace':
      return '넓어요';
    case 'smallSpace':
      return '아담해요';
    case 'average':
      return '보통이에요';
    case 'easy':
      return '편해요';
    case 'hard':
      return '어려워요';
    case 'clean':
      return '청결해요';
    case 'kind':
      return '친절해요';
    case 'thorough':
      return '꼼꼼해요';
    case 'no':
      return '아니에요';
    case 'strong':
      return '강해요';
    case 'weak':
      return '약해요';
    case 'do':
      return '해요';
    case 'dont':
      return '안해요';
    case 'littleSick':
      return '조금 아플때';
    case 'verySick':
      return '많이 아플때';
    case 'below1day':
      return '당일 바로';
    case 'below7day':
      return '일주일 이내';
    case 'over7day':
      return '일주일 이상';
    default:
      print('Failed to convert option to string');
      return option;
  }
}

Widget getSurveySectionTitle(String string) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      string,
      style: TextStyle(
        color: appTheme().primaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
