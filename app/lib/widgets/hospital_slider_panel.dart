import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/data/hospital.dart';
import 'package:kids_info_app/helpers/hospital_search_helper.dart';
import 'package:kids_info_app/screens/detail_page.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class HospitalSliderPanel extends StatefulWidget {
  final List<Hospital> hospitals;
  final PanelController panelController;
  final ScrollController scrollController;
  final String focusedHospitalId;
  final void Function(String) onListItemTapped;
  final VoidCallback onDetailPageBackButtonPressed;

  const HospitalSliderPanel({
    Key? key,
    required this.hospitals,
    required this.panelController,
    required this.scrollController,
    required this.focusedHospitalId,
    required this.onListItemTapped,
    required this.onDetailPageBackButtonPressed,
  }) : super(key: key);

  @override
  _HospitalSliderPanelState createState() => _HospitalSliderPanelState();
}

class _HospitalSliderPanelState extends State<HospitalSliderPanel> {
  bool _isPanelOpen = false;
  bool _isInfoOpen = true;

  String getCurrentOperationInfo(Hospital hospital) {
    switch (hospital.operatingStatus) {
      case HospitalOperatingStatus.open:
        return '현재 진료중';
      default:
        return '';
    }
  }

  String getTodayOperationInfo(Hospital hospital) {
    String hours = hospital.getTodayOperatingHours();
    return hospital.hasOperatingHourInfo()
        ? (hours.isNotEmpty ? '오늘 진료 $hours' : '오늘 휴무')
        : '진료시간 정보없음';
  }

  Widget getTopSection() {
    return FutureBuilder<bool>(
      future: getIsTodayHoliday(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (_isInfoOpen && snapshot.hasData && snapshot.data) {
          return Padding(
            padding: const EdgeInsets.only(
                top: sliderPanelMinHeight, left: 10, right: 10),
            child: Container(
              decoration: BoxDecoration(
                color: appTheme().primaryColorLight,
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.info_outline,
                    size: 20.0,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('공휴일 진료는 변동될 수 있으니 반드시 병원에 확인 후 방문해주세요.'),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 30,
                    child: IconButton(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(0),
                      iconSize: 20,
                      icon: const Icon(
                        Icons.close,
                      ),
                      onPressed: () {
                        setState(() {
                          _isInfoOpen = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox(height: sliderPanelMinHeight);
        }
      },
    );
  }

  Widget getTileSubtitle(Hospital hospital) {
    return Row(
      children: [
        Text(getTodayOperationInfo(hospital)),
        const SizedBox(width: 10),
        Text(
          getCurrentOperationInfo(hospital),
          style: TextStyle(
            color: appTheme().primaryColor,
          ),
        ),
      ],
    );
  }

  Widget getTileTrailling(Hospital hospital, bool isSelected) {
    NumberFormat formatter = NumberFormat.compact();
    formatter.maximumFractionDigits = 1;
    formatter.significantDigitsInUse = false;
    String likeCount =
        hospital.likeCount == 0 ? '' : formatter.format(hospital.likeCount);
    String surveyCount =
        hospital.surveyCount == 0 ? '' : formatter.format(hospital.surveyCount);
    return SizedBox(
      width: sliderPanelListTileTrailingWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Property
          SizedBox(
            width: sliderPanelListTileTrailingPropertyWidth,
            child: Column(
              children: [
                // Spacing
                const SizedBox(height: 5),
                // Like
                SizedBox(
                  child: likeCount.isEmpty
                      ? Container()
                      : Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.black54,
                              size: 15,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  likeCount,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                // Surveys
                Expanded(
                  child: surveyCount.isEmpty
                      ? Container()
                      : Row(
                          children: [
                            const Icon(
                              Icons.edit_document,
                              color: Colors.black54,
                              size: 15,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  surveyCount,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          // More button
          if (isSelected)
            Container(
              color: Colors.transparent,
              width: sliderPanelListTileTrailingWidth -
                  sliderPanelListTileTrailingPropertyWidth,
              child: FloatingActionButton(
                heroTag: null,
                foregroundColor: appTheme().primaryColorDark,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                elevation: 0,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(
                        hospital: hospital,
                        onBackPressed: widget.onDetailPageBackButtonPressed,
                      ),
                    ),
                  );
                },
                backgroundColor:
                    isSelected ? appTheme().primaryColorLight : Colors.white,
                child: const Column(
                  children: [
                    SizedBox(height: 3),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 30,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '병원정보',
                      style: TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget getBodySection() {
    return Expanded(
      child: Scrollbar(
        controller: widget.scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: widget.scrollController,
          itemExtent: sliderPanelListTileHeight,
          itemCount: widget.hospitals.length,
          itemBuilder: (context, index) {
            Hospital hospital = widget.hospitals[index];
            bool isSelected = hospital.id == widget.focusedHospitalId;
            return Material(
              child: ListTile(
                contentPadding: const EdgeInsets.only(left: 15),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                  color: appTheme().primaryColorDark,
                  width: 0.1,
                )),
                title: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: 1.2,
                  child: Text(
                    hospital.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
                subtitle: getTileSubtitle(hospital),
                trailing: getTileTrailling(hospital, isSelected),
                selected: isSelected,
                selectedColor: appTheme().primaryColorDark,
                selectedTileColor: appTheme().primaryColorLight,
                onTap: () {
                  widget.onListItemTapped(hospital.id);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.hospitals.isNotEmpty)
          ElevatedButton(
            onPressed: () {
              if (_isPanelOpen) {
                widget.panelController.close();
              } else {
                widget.panelController.open();
              }
            },
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
            ),
            child: Text(
              _isPanelOpen ? '목록 숨기기' : '목록으로 보기',
              // style: const TextStyle(color: Colors.black),
            ),
          ),
        SlidingUpPanel(
          controller: widget.panelController,
          minHeight: widget.hospitals.isNotEmpty ? sliderPanelMinHeight : 0,
          maxHeight: sliderPanelMaxHeight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18.0)),
          onPanelClosed: () {
            setState(() => _isPanelOpen = false);
          },
          onPanelOpened: () {
            setState(() => _isPanelOpen = true);
          },
          panel: Column(
            children: [
              getTopSection(),
              getBodySection(),
            ],
          ),
        ),
      ],
    );
  }
}
