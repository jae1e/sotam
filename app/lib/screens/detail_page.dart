import 'dart:math';

import 'package:bubble/bubble.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/data/hospital.dart';
import 'package:kids_info_app/data/survey_answer.dart';
import 'package:kids_info_app/data/survey_summary.dart';
import 'package:kids_info_app/helpers/like_helper.dart';
import 'package:kids_info_app/helpers/survey_helper.dart';
import 'package:kids_info_app/helpers/user_helper.dart';
import 'package:kids_info_app/screens/survey_page.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:kids_info_app/widgets/banner_ad_widget.dart';
import 'package:kids_info_app/widgets/detail_info_row.dart';
import 'package:kids_info_app/widgets/detail_url_row.dart';
import 'package:kids_info_app/widgets/survey_summary_chart.dart';

class DetailPage extends StatefulWidget {
  final Hospital hospital;
  final VoidCallback onBackPressed;

  const DetailPage(
      {super.key, required this.hospital, required this.onBackPressed});

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  late TabController _tabController;
  String getOperatingHourDescription(Hospital hospital) {
    if (!hospital.hasOperatingHourInfo()) {
      return '진료시간 정보없음';
    }
    List<String> dayStr = [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
      '공휴일'
    ];
    List<String> outputList = [];
    for (int day = 1; day < dayStr.length + 1; day++) {
      var hourStr = hospital.getOperatingHours(day);
      if (hourStr.isNotEmpty) {
        outputList.add('${dayStr[day - 1]}: $hourStr');
      } else {
        outputList.add('${dayStr[day - 1]}: 휴무');
      }
    }
    return outputList.join('\n');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _scrollController.position.isScrollingNotifier.addListener(() {
        if (_scrollController.position.isScrollingNotifier.value) {
          // Scroll starts
          setState(() {
            _isScrolling = true;
          });
        } else {
          // Scroll ends
          setState(() {
            _isScrolling = false;
          });
        }
      });
    });

    // Firebase logging
    try {
      FirebaseAnalytics.instance.logScreenView(
        screenClass: 'page',
        screenName: 'detail',
        parameters: {
          'hospital_id': widget.hospital.id,
          'hospital_name': widget.hospital.name,
        },
      );
    } catch (e) {
      print('Firebase analytics: failed to log detail screen view');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget getAppBarLikeButton(Hospital hospital) {
    return SizedBox(
      width: detailLikeButtonWidth,
      height: detailLikeButtonHeight,
      child: TextButton(
        onPressed: null,
        style: const ButtonStyle(
          side: MaterialStatePropertyAll(BorderSide(
            color: Colors.black87,
            width: 0.3,
          )),
          foregroundColor: MaterialStatePropertyAll(Colors.black87),
          backgroundColor: MaterialStatePropertyAll(Colors.transparent),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5))),
          ),
          padding: MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.favorite_border,
              color: Colors.pinkAccent,
              size: 16,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: FutureBuilder<int>(
                  future: getLikeCount(hospital),
                  builder: (BuildContext context2, AsyncSnapshot snapshot2) {
                    if (snapshot2.hasError || !snapshot2.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      int count = snapshot2.data;
                      NumberFormat formatter = NumberFormat.compact();
                      formatter.maximumFractionDigits = 1;
                      formatter.significantDigitsInUse = false;
                      return Text(
                        formatter.format(count),
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getBasicInfoSection(Hospital hospital) {
    String infoStr = hospital.getDetailInfo();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.ideographic,
      children: [
        DetailUrlRow(
            icon: Icons.location_on_outlined,
            text: hospital.address,
            type: DetailUrlRowType.address),
        DetailUrlRow(
            icon: Icons.phone_outlined,
            text: hospital.phone,
            type: DetailUrlRowType.phone),
        DetailInfoRow(icon: Icons.local_hospital_outlined, text: hospital.type),
        DetailInfoRow(
            icon: Icons.cases_outlined, text: hospital.subjects.join(', ')),
        DetailInfoRow(
            icon: Icons.access_time,
            text: getOperatingHourDescription(hospital)),
        if (infoStr.isNotEmpty)
          DetailInfoRow(icon: Icons.info_outline, text: infoStr),
      ],
    );
  }

  Widget getSurveyHeader(int totalCount) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '총 $totalCount분이 설문에 응답해주셨어요',
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }

  Widget getSurveySummaryChart(
      String questionKey, Map<String, SurveySummary> summaries) {
    if (!summaries.containsKey(questionKey)) {
      return const SizedBox();
    }
    // For now, support selection only
    SurveySummary summary = summaries[questionKey]!;
    if (summary.type != SurveyQuestionType.selection) {
      return const SizedBox();
    }

    return SurveySummaryChart(
        questionKey: questionKey,
        options: summary.options,
        optionCounts: summary.optionCounts);
  }

  Widget getSurveySummaryChartList(SurveySummaryResponse summaryResponse) {
    var summaries = summaryResponse.summaries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.ideographic,
      children: [
        getSurveyHeader(summaryResponse.totalCount),
        //
        getSurveySectionTitle('공간'),
        getSurveySummaryChart('waitingSpace', summaries),
        getSurveySummaryChart('cleanliness', summaries),
        getSurveySummaryChart('parkingDifficulty', summaries),
        //
        getSurveySectionTitle('진료 / 치료 / 처방'),
        getSurveySummaryChart('kindness', summaries),
        getSurveySummaryChart('thoroughness', summaries),
        getSurveySummaryChart('medicineStrength', summaries),
        getSurveySummaryChart('ivTreatment', summaries),
        getSurveySummaryChart('whenToVisit', summaries),
        //
        getSurveySectionTitle('영유아 검진'),
        getSurveySummaryChart('checkupAvailable', summaries),
        getSurveySummaryChart('checkupWaiting', summaries),
      ],
    );
  }

  Widget getSurveyWarningView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Image.asset(
              'assets/images/kids_search_icon_no_bg_360.png',
              width: appIconSize,
              height: appIconSize,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getSurveySection(Hospital hospital) {
    // Step 1: check if user has submitted survey
    return FutureBuilder<int>(
      future: getUserSurveyCount(),
      builder: (BuildContext context1, AsyncSnapshot snapshot1) {
        if (snapshot1.hasError || !snapshot1.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot1.data == 0) {
          return getSurveyWarningView('설문에 참여하시면 병원에 대한 다른 분들의 응답을 보실 수 있어요.\n'
              '어느 병원이든 하나만 작성해 주시면 됩니다.\n'
              '작성해 주신 설문은 이 병원을 찾으시는 분들께 큰 도움이 됩니다.');
        }

        // Step 2: check if there is survey result in DB
        return FutureBuilder<SurveySummaryResponse>(
            future: getSurveySummary(hospital),
            builder: (BuildContext context2, AsyncSnapshot snapshot2) {
              if (snapshot2.hasError) {
                return const Center(
                  child: Text(
                    '서버 오류가 발생했습니다.',
                    style: TextStyle(fontSize: 15),
                  ),
                );
              } else if (!snapshot2.hasData) {
                return const Center(child: CircularProgressIndicator());
              } else {
                SurveySummaryResponse response = snapshot2.data;
                if (response.totalCount == 0) {
                  return getSurveyWarningView('아직 이 병원에 대한 설문 결과가 없습니다.\n'
                      '${hospital.name}에 대해 아신다면 간단한 설문에 답해주세요.');
                } else {
                  // Step 3: show summary result
                  return getSurveySummaryChartList(response);
                }
              }
            });
      },
    );
  }

  Widget getSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: appTheme().primaryColorDark,
        ),
      ),
    );
  }

  Widget getSectionSplitter() {
    AdSize defaultSize = AdSize.fullBanner;
    double width =
        min(MediaQuery.of(context).size.width, defaultSize.width.toDouble());
    double height =
        (width / defaultSize.width.toDouble()) * defaultSize.height.toDouble();
    return Container(
      alignment: Alignment.center,
      color: Colors.grey[200],
      width: width,
      height: height + 10,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: BannerAdWidget(
        adSize: AdSize(width: width.toInt(), height: height.toInt()),
      ),
    );
  }

  Widget getFloatingLikeButton(Hospital hospital) {
    return FutureBuilder<bool>(
      future: getLikeFound(hospital),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasError && snapshot.hasData) {
          bool liked = snapshot.data;
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!liked && !_isScrolling)
                Bubble(
                  padding:
                      const BubbleEdges.symmetric(vertical: 5, horizontal: 8),
                  nip: BubbleNip.rightCenter,
                  borderColor: appTheme().primaryColorDark,
                  borderWidth: 0.1,
                  child: const Text(
                    '이 병원을 추천해요',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              const SizedBox(width: 10),
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  // Post liked and update UI
                  postLike(hospital, !liked).then((_) => setState(() {}));
                },
                shape: const CircleBorder(),
                child: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? Colors.pinkAccent : Colors.white,
                ),
              ),
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget getWriteSurveyButton(Hospital hospital) {
    return FutureBuilder<SurveyAnswerDocument>(
      future: getSurveyAnswer(hospital),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasError && snapshot.hasData) {
          SurveyAnswerDocument answerDocument = snapshot.data;
          String timestamp = answerDocument.timestamp;
          if (timestamp.contains(" ")) {
            timestamp = timestamp.split(" ")[0];
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!_isScrolling)
                Bubble(
                  padding:
                      const BubbleEdges.symmetric(vertical: 5, horizontal: 8),
                  nip: BubbleNip.rightCenter,
                  borderColor: appTheme().primaryColorDark,
                  borderWidth: 0.1,
                  child: answerDocument.answers.isEmpty
                      ? const Text(
                          '이 병원에 대해 아시나요?\n간단한 설문에 답해주세요',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 15),
                        )
                      : Text(
                          '내 응답 수정하기\n($timestamp에 제출)',
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 15),
                        ),
                ),
              const SizedBox(width: 10),
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SurveyPage(
                              hospital: hospital,
                              originalAnswers: answerDocument.answers))).then(
                      (_) =>
                          setState(() {})); // Update page when survey page pops
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.edit_document),
              ),
            ],
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Hospital hospital = widget.hospital;
    var sectionPadding = const EdgeInsets.all(15);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(hospital.name),
                  ),
                ),
              ),
            ),
            getAppBarLikeButton(hospital),
          ],
        ),
        leading: BackButton(onPressed: () {
          widget.onBackPressed();
          Navigator.of(context).pop();
        }),
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Basic info
                getSectionTitle('기본 정보'),
                Padding(
                  padding: sectionPadding,
                  child: getBasicInfoSection(hospital),
                ),
                getSectionSplitter(),
                // Survey result
                getSectionTitle('설문 정보'),
                Padding(
                  padding: sectionPadding,
                  child: getSurveySection(hospital),
                ),
                // Margin for button descriptions
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          getFloatingLikeButton(hospital),
          const SizedBox(
            height: 15,
          ),
          getWriteSurveyButton(hospital),
        ],
      ),
    );
  }
}
