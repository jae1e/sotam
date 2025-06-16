import 'package:flutter/material.dart';
import 'package:kids_info_app/helpers/toast_helper.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum DetailUrlRowType {
  phone,
  address,
}

class DetailUrlRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final DetailUrlRowType type;

  const DetailUrlRow({
    Key? key,
    required this.icon,
    required this.text,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 10), // Space between icon and text
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                  overflow: TextOverflow.visible,
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blueAccent),
              onTap: () async {
                if (type == DetailUrlRowType.phone) {
                  String url = 'tel:$text';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    showToast('통화앱을 열지 못했습니다.\n전화번호를 통화앱에 직접 붙여넣어 주세요.');
                  }
                } else if (type == DetailUrlRowType.address) {
                  MapsLauncher.launchQuery(text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
