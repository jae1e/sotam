import 'package:flutter/material.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/screens/info_page.dart';
import 'package:kids_info_app/helpers/info_helper.dart';

class AppIcon extends StatefulWidget {
  const AppIcon({super.key});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Image.asset(
            'assets/images/kids_search_icon_no_bg_360.png',
            width: appIconSize,
            height: appIconSize,
          ),
          FutureBuilder<bool>(
            future: isInfoPageUpdated(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasError || !snapshot.hasData || !snapshot.data) {
                return Container();
              } else {
                return SizedBox(
                  width: appIconSize,
                  height: appIconSize,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      width: appIconBadgeSize,
                      height: appIconBadgeSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            fontSize: appIconBadgeSize / 2,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
                context, MaterialPageRoute(builder: (context) => InfoPage()))
            .then((_) => setState(() {}));
      },
    );
  }
}
