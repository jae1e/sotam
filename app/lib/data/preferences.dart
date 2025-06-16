import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static late final SharedPreferences _instance;

  static Future<void> initialize() async {
    _instance = await SharedPreferences.getInstance();
  }

  static SharedPreferences getInstance() {
    return _instance;
  }
}
