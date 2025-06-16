import 'dart:ui';
import 'package:kids_info_app/helpers/calendar_helper.dart';

class CalendarPerson {
  String name;
  Color color;

  CalendarPerson(this.name, this.color);
}

class CalendarEvent {
  DateTime time = DateTime.now();
  String personName = '';
  String description = '';

  CalendarEvent(this.time, this.personName, this.description);
}

class Calendar {
  List<CalendarPerson> persons = [];
  List<CalendarEvent> events = [];

  List<CalendarEvent> getEventsOfDay(DateTime day) {
    List<CalendarEvent> result = [];
    for (CalendarEvent event in events) {
      int compare = compareDay(event.time, day);
      if (compare == 0) {
        result.add(event);
      } else if (compare == 1) {
        // Assuming event is sorted by date,
        // break if event's date passes day for performance
        break;
      }
    }
    return result;
  }
}
