import 'package:flutter/material.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/helpers/survey_helper.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SurveySummaryChart extends StatelessWidget {
  final String questionKey;
  final List<String> options;
  final List<int> optionCounts;

  const SurveySummaryChart({
    super.key,
    required this.questionKey,
    required this.options,
    required this.optionCounts,
  });

  @override
  Widget build(BuildContext context) {
    int sum = optionCounts.reduce((value, element) => value + element);
    return Padding(
      padding: const EdgeInsets.only(left: 7.0, bottom: 15.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(getSurveyQuestionDescription(questionKey),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 5),
        SizedBox(
          width: optionCounts.length * surveySummaryTickWidth,
          height: surveySummaryHeight,
          child: SfCartesianChart(
            isTransposed: true,
            margin: const EdgeInsets.all(5),
            plotAreaBorderWidth: 0,
            primaryXAxis: const CategoryAxis(
              axisLine: AxisLine(width: 0),
              majorTickLines: MajorTickLines(width: 0),
              majorGridLines: MajorGridLines(width: 0),
              labelStyle: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            primaryYAxis: const NumericAxis(
              minimum: 0.0,
              maximum: 1.2,
              isVisible: false,
              interactiveTooltip: InteractiveTooltip(),
            ),
            series: <CartesianSeries<String, String>>[
              BarSeries<String, String>(
                dataSource: options,
                xValueMapper: (String key, _) =>
                    getSurveyAnswerOptionDescription(key),
                yValueMapper: (_, int index) => optionCounts[index] / sum,
                width: surveySummaryBarWidth,
                animationDuration: 750,
                color: appTheme().primaryColor,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  margin: EdgeInsets.only(bottom: 1),
                ),
                dataLabelMapper: (_, int index) =>
                    '${(optionCounts[index] / sum * 100).toInt()}%',
              )
            ],
          ),
        ),
      ]),
    );
  }
}
