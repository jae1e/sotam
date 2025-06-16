import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> isLocationPermissionGranted() async {
  return Permission.locationWhenInUse.status.isGranted;
}

Future<bool> requestLocationPermission() async {
  if (await isLocationPermissionGranted()) {
    return true;
  }
  PermissionStatus status = await Permission.locationWhenInUse.request();
  return status.isGranted;
}

void showPermissionDeniedDialog(BuildContext context) {
  String message = '이 앱을 잘 사용하려면 위치 권한이 필요합니다. 위치 권한 허용을 위해 지금 설정으로 이동하시겠어요?';
  if (Platform.isIOS) {
    message += '\n\n설정 > 개인정보 보호 > 위치 서비스로 이동하여 권한을 변경하실 수 있습니다.';
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('위치 권한 허용'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('예'),
            onPressed: () {
              openAppSettings(); // This opens the app settings
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('아니오'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
