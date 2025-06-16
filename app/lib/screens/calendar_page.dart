import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/info.dart';
import 'package:kids_info_app/data/preferences.dart';
import 'package:kids_info_app/helpers/info_helper.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이 상태 기록하기'),
        leading: BackButton(onPressed: () {
          Navigator.of(context).pop();
        }),
      ),
      body: SafeArea(
        child: TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime(2023, 1, 1),
          lastDay: DateTime(2043, 12, 31),
          focusedDay: _focusedDay,
          onPageChanged: (DateTime focusedDay) {
            // TODO: load monthly events data from server
          },
          eventLoader: (DateTime day) {
            return [1, 2, 3, 4, 5];
          },
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontSize: 20.0,
            ),
            headerPadding: EdgeInsets.only(top: 20.0, bottom: 5),
            leftChevronIcon: Icon(
              Icons.arrow_left,
              size: 40.0,
            ),
            rightChevronIcon: Icon(
              Icons.arrow_right,
              size: 40.0,
            ),
          ),
          calendarStyle: CalendarStyle(
            todayTextStyle: const TextStyle(
              color: Color(0xFFFAFAFA),
              fontSize: 16.0,
            ),
            todayDecoration: const BoxDecoration(
              color: Color(0xFF9FA8DA),
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
            ),
            selectedDecoration: BoxDecoration(
              color: appTheme().primaryColorDark,
              shape: BoxShape.circle,
            ),
          ),
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
        ),
      ),
    );
  }
}
