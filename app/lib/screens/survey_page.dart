import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/data/hospital.dart';
import 'package:kids_info_app/data/survey_answer.dart';
import 'package:kids_info_app/data/survey_question.dart';
import 'package:kids_info_app/helpers/survey_helper.dart';
import 'package:kids_info_app/widgets/survey_option_selector.dart';

class SurveyPage extends StatefulWidget {
  final Hospital hospital;
  final Map<String, SurveyAnswer> originalAnswers;

  const SurveyPage({super.key, required this.hospital, required this.originalAnswers});

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  Map<String, SurveyAnswer> _answers = {};

  @override
  void initState() {
    _answers = widget.originalAnswers;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget getInfoSection() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline),
        SizedBox(width: 10),
        Expanded(
          child: Text('병원에 대해 알고 계신 정보를 공유해주세요.\n'
              '잘 모르는 질문에는 응답하지 않으셔도 됩니다.\n'
              '선택한 버튼을 다시 누르면 선택이 취소됩니다.'),
        ),
      ],
    );
  }

  Widget getSurveyOptionSelector(
      String questionKey, Map<String, SurveyQuestion> questions) {
    return questions.containsKey(questionKey)
        ? SurveyOptionSelector(
            questionKey: questionKey,
            options: questions[questionKey]!.options,
            currentOption: _answers[questionKey]?.option ?? "",
            onSelectionChanged: (String option) {
              setState(() {
                if (option.isNotEmpty) {
                  if (!_answers.containsKey(questionKey)) {
                    // Create answer object if it doesn't exist
                    _answers[questionKey] =
                        SurveyAnswer(SurveyQuestionType.selection, option, "");
                  } else {
                    // Update option
                    _answers[questionKey]!.option = option;
                  }
                } else {
                  // Delete answer object if it exists
                  _answers.removeWhere((k, v) => k == questionKey);
                }
              });
            })
        : const SizedBox();
  }

  Widget getSubmitCancelSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Center(
        child: ElevatedButton(
          onPressed: _answers.isNotEmpty
              ? () {
            submitSurveyAnswer(widget.hospital, _answers).then((result) {
              // Firebase logging
              try {
                FirebaseAnalytics.instance.logEvent(
                  name: 'submit_survey',
                  parameters: {
                    'hospital_id': widget.hospital.id,
                    'hospital_name': widget.hospital.name,
                    'result': result,
                  },
                );
              } catch (e) {
                print('Firebase analytics: failed to log survey submission');
              }

              if (result) {
                Navigator.of(context).pop();
              }
            });
          } : null,
          style: const ButtonStyle(
            padding: MaterialStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
            ),
          ),
          child: const Text(
            '제출하기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget getSurveyPageBody(BuildContext context, AsyncSnapshot snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return const Center(
        child: Text(
          '서버 오류가 발생했습니다.',
          style: TextStyle(fontSize: 15),
        ),
      );
    } else {
      Map<String, SurveyQuestion> questions =
          (snapshot.data as SurveyQuestionsResponse).questions;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 15.0, right: 10.0),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                //
                const SizedBox(height: 10),
                getInfoSection(),
                const SizedBox(height: 10),
                //
                getSurveySectionTitle('공간'),
                getSurveyOptionSelector('waitingSpace', questions),
                getSurveyOptionSelector('cleanliness', questions),
                getSurveyOptionSelector('parkingDifficulty', questions),
                //
                getSurveySectionTitle('진료 / 치료 / 처방'),
                getSurveyOptionSelector('kindness', questions),
                getSurveyOptionSelector('thoroughness', questions),
                getSurveyOptionSelector('medicineStrength', questions),
                getSurveyOptionSelector('ivTreatment', questions),
                getSurveyOptionSelector('whenToVisit', questions),
                //
                getSurveySectionTitle('영유아 검진'),
                getSurveyOptionSelector('checkupAvailable', questions),
                if (_answers['checkupAvailable']?.option == 'do')
                  getSurveyOptionSelector('checkupWaiting', questions),
                //
                getSubmitCancelSection(context),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getSurveyQuestions(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.hospital.name),
              leading: BackButton(onPressed: () => Navigator.of(context).pop()),
            ),
            body: SafeArea(
              child: getSurveyPageBody(context, snapshot),
            ),
          );
        });
  }
}
