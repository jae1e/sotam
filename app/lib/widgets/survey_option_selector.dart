import 'package:flutter/material.dart';
import 'package:kids_info_app/helpers/survey_helper.dart';
import 'package:kids_info_app/theme/style.dart';

class SurveyOptionSelector extends StatelessWidget {
  final String questionKey;
  final List<String> options;
  final String currentOption;
  final void Function(String) onSelectionChanged;

  const SurveyOptionSelector({
    super.key,
    required this.questionKey,
    required this.options,
    required this.currentOption,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 7.0, bottom: 15.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(getSurveyQuestionDescription(questionKey),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: options.map((option) {
              bool isSelected = currentOption == option;
              return ElevatedButton(
                  onPressed: () {
                    onSelectionChanged(isSelected ? '' : option);
                  },
                  style: ButtonStyle(
                    padding: const MaterialStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 7.0)),
                    backgroundColor: MaterialStatePropertyAll(
                        isSelected ? appTheme().primaryColor : Colors.white),
                    foregroundColor: MaterialStatePropertyAll(
                        isSelected ? Colors.white : Colors.black),
                  ),
                  child: Text(getSurveyAnswerOptionDescription(option)));
            }).toList(),
          ),
        ),
      ]),
    );
  }
}
