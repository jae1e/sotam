import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:kids_info_app/widgets/hospital_filter_selector.dart';
import 'package:flutter/cupertino.dart';

class FloatingButtonSection extends StatefulWidget {
  final bool isSearchingInProgress;
  final bool isLocatingInProgress;
  final VoidCallback onRefreshPressed;
  final VoidCallback onLocateMe;
  final void Function(HospitalTypeFilter, HospitalStatusFilter) onFilterChanged;
  final void Function(bool) onShowHospitalsChanged;

  FloatingButtonSection({
    required this.isSearchingInProgress,
    required this.isLocatingInProgress,
    required this.onRefreshPressed,
    required this.onLocateMe,
    required this.onFilterChanged,
    required this.onShowHospitalsChanged,
  });

  @override
  State<FloatingButtonSection> createState() => _FloatingButtonSectionState();
}

class _FloatingButtonSectionState extends State<FloatingButtonSection> {
  HospitalTypeFilter _typeFilter = HospitalTypeFilter.allType;
  HospitalStatusFilter _statusFilter = HospitalStatusFilter.allStatus;
  bool _isRefreshTooltipVisible = false;
  bool _isLocationTooltipVisible = false;
  bool _isHideTooltipVisible = false;
  bool _showHospital = true;

  Widget getFloatingButtonTooltip(String text) {
    return Bubble(
      padding: const BubbleEdges.symmetric(
        vertical: floatingSectionTooltipVerticalPadding,
        horizontal: floatingSectionTooltipHorizontalPadding,
      ),
      nip: BubbleNip.leftCenter,
      color: appTheme().primaryColor,
      child: SizedBox(
        height: floatingSectionTooltipHeight,
        child: Text(
          text,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget getRefreshButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: floatingSectionButtonWidth,
          height: floatingSectionButtonHeight,
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor: appTheme().primaryColor,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(floatingSectionButtonBorderRadius))),
            onPressed: widget.isSearchingInProgress
                ? null
                : () {
                    widget.onRefreshPressed();
                    // Show tooltip
                    setState(() {
                      _isRefreshTooltipVisible = true;
                    });
                    // Hide the tooltip after seconds
                    Future.delayed(
                        const Duration(seconds: floatingSectionTooltipDuration),
                        () => setState(() {
                              _isRefreshTooltipVisible = false;
                            }));
                  },
            child: widget.isSearchingInProgress
                ? const SizedBox(
                    width: searchProgressSize,
                    height: searchProgressSize,
                    child: CircularProgressIndicator(
                      strokeWidth: searchProgressThickness,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ),
        // Tooltip
        if (_isRefreshTooltipVisible) const SizedBox(width: 3),
        if (_isRefreshTooltipVisible) getFloatingButtonTooltip("병원 새로고침"),
      ],
    );
  }

  Widget getMyLocationButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: floatingSectionButtonWidth,
          height: floatingSectionButtonHeight,
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor: widget.isLocatingInProgress
                ? appTheme().primaryColorLight
                : appTheme().primaryColor,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(floatingSectionButtonBorderRadius))),
            onPressed: widget.isLocatingInProgress ? null : () {
              widget.onLocateMe();
              // Show tooltip
              setState(() {
                _isLocationTooltipVisible = true;
              });
              // Hide the tooltip after seconds
              Future.delayed(
                  const Duration(seconds: floatingSectionTooltipDuration),
                  () => setState(() {
                        _isLocationTooltipVisible = false;
                      }));
            },
            child: const Icon(Icons.my_location),
          ),
        ),
        // Tooltip
        if (_isLocationTooltipVisible) const SizedBox(width: 3),
        if (_isLocationTooltipVisible) getFloatingButtonTooltip("내 위치로"),
      ],
    );
  }

  Widget getHideButton() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: floatingSectionButtonWidth,
          height: floatingSectionButtonHeight,
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor:
                _showHospital ? appTheme().primaryColor : Colors.redAccent,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(floatingSectionButtonBorderRadius))),
            onPressed: widget.isSearchingInProgress
                ? null
                : () {
                    setState(() {
                      _showHospital = !_showHospital;
                    });
                    widget.onShowHospitalsChanged(_showHospital);
                    // Show tooltip
                    setState(() {
                      _isHideTooltipVisible = true;
                    });
                    // Hide the tooltip after seconds
                    Future.delayed(
                        const Duration(seconds: floatingSectionTooltipDuration),
                        () => setState(() {
                              _isHideTooltipVisible = false;
                            }));
                  },
            child: const Icon(CupertinoIcons.eye_slash),
          ),
        ),
        // Tooltip
        if (_isHideTooltipVisible) const SizedBox(width: 3),
        if (_isHideTooltipVisible) getFloatingButtonTooltip("병원 전체 숨김 / 보기"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Refresh
                getRefreshButton(),
                const SizedBox(height: 15),
                // 내위치
                getMyLocationButton(),
                const SizedBox(height: 15),
                // 보기
                getHideButton(),
              ],
            ),
            // Right column
            Column(
              children: [
                // 분류
                HospitalFilterSelector(
                  title: '분류',
                  filters:
                      HospitalTypeFilter.values.map((e) => e.name).toList(),
                  currentFilter: _typeFilter.name,
                  isSearchingInProgress: widget.isSearchingInProgress,
                  onSelectionChanged: (String filter) {
                    if (_typeFilter.name != filter) {
                      setState(() {
                        _typeFilter = HospitalTypeFilter.values.firstWhere(
                            (e) => e.name == filter,
                            orElse: () => HospitalTypeFilter.allType);
                      });
                      widget.onFilterChanged(_typeFilter, _statusFilter);
                    }
                  },
                ),
                const SizedBox(height: 15),
                // 진료
                HospitalFilterSelector(
                  title: '진료',
                  filters:
                      HospitalStatusFilter.values.map((e) => e.name).toList(),
                  currentFilter: _statusFilter.name,
                  isSearchingInProgress: widget.isSearchingInProgress,
                  onSelectionChanged: (String filter) {
                    if (_statusFilter.name != filter) {
                      setState(() {
                        _statusFilter = HospitalStatusFilter.values.firstWhere(
                            (e) => e.name == filter,
                            orElse: () => HospitalStatusFilter.allStatus);
                      });
                      widget.onFilterChanged(_typeFilter, _statusFilter);
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    ]);
  }
}
