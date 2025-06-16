import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/theme/style.dart';

class HospitalFilterSelector extends StatefulWidget {
  final String title;
  final List<String> filters;
  final String currentFilter;
  final bool isSearchingInProgress;
  final void Function(String) onSelectionChanged;

  const HospitalFilterSelector({
    Key? key,
    required this.title,
    required this.filters,
    required this.currentFilter,
    required this.isSearchingInProgress,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<HospitalFilterSelector> createState() => _HospitalFilterSelectorState();
}

class _HospitalFilterSelectorState extends State<HospitalFilterSelector> {
  final GlobalKey _titleBoxKey = GlobalKey();
  OverlayEntry? _tooltipOverlay;

  String getFilterIconText(String filter) {
    switch (filter) {
      case 'allType':
        return '전체';
      case 'allStatus':
        return '전체';
      case 'pediatrics':
        return '소아';
      case 'moonlight':
        return '달빛';
      case 'openToday':
        return '오늘';
      case 'openNow':
        return '현재';
      case 'openSunday':
        return '일요';
      default:
        return filter;
    }
  }

  String getFilterTooltipText(String filter) {
    switch (filter) {
      case 'allType':
        return '소아과 진료하는 병원';
      case 'pediatrics':
        return '소아과만';
      case 'moonlight':
        return '달빛어린이병원만';
      case 'allStatus':
        return '전체 보기';
      case 'openToday':
        return '오늘 진료하는 병원만';
      case 'openNow':
        return '현재 진료중인 병원만';
      case 'openSunday':
        return '일요일에 진료하는 병원만';
      default:
        return filter;
    }
  }

  OverlayEntry? createTooltipOverlay() {
    if (_titleBoxKey.currentContext == null) {
      return null;
    }

    RenderBox renderBox =
        _titleBoxKey.currentContext!.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        right: renderBox.paintBounds.right + 12,
        top: offset.dy +
            0.5 * floatingSectionButtonTitleHeight +
            0.5 * floatingSectionFilterHeight -
            5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: widget.filters
              .map((filter) {
                return Material(
                  color: Colors.transparent,
                  child: Bubble(
                    margin: const BubbleEdges.only(
                        bottom: floatingSectionTooltipMargin),
                    padding: const BubbleEdges.symmetric(
                      vertical: floatingSectionTooltipVerticalPadding,
                      horizontal: floatingSectionTooltipHorizontalPadding,
                    ),
                    alignment: Alignment.centerRight,
                    nip: BubbleNip.rightCenter,
                    color: appTheme().primaryColor,
                    child: SizedBox(
                      height: floatingSectionTooltipHeight,
                      child: Text(
                        getFilterTooltipText(filter),
                        textAlign: TextAlign.end,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                );
              })
              .cast<Widget>()
              .toList(),
        ),
      ),
    );
  }

  void disposeTooltipOverlay() {
    if (_tooltipOverlay != null) {
      _tooltipOverlay?.remove();
      _tooltipOverlay = null;
    }
  }

  void showTooltip() {
    // Dispose if tooltip is already visible
    disposeTooltipOverlay();

    // Create tooltip
    _tooltipOverlay = createTooltipOverlay();
    if (_tooltipOverlay == null) {
      return;
    }

    Overlay.of(context).insert(_tooltipOverlay!);

    // Hide the popover after seconds
    Future.delayed(const Duration(seconds: floatingSectionTooltipDuration),
        () => disposeTooltipOverlay());
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme().primaryColor,
          borderRadius:
              BorderRadius.circular(floatingSectionButtonBorderRadius),
        ),
        child: Column(
          children: <Widget>[
                SizedBox(
                  key: _titleBoxKey,
                  width: floatingSectionButtonWidth,
                  height: floatingSectionButtonTitleHeight,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ] +
              widget.filters.map((filter) {
                bool isSelected = widget.currentFilter == filter;
                return SizedBox(
                  width: floatingSectionButtonWidth,
                  height: floatingSectionFilterHeight,
                  child: FloatingActionButton(
                    heroTag: null,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: appTheme().primaryColorDark,
                        width: floatingSectionButtonBorderWidth,
                      ),
                    ),
                    elevation: 0,
                    onPressed: widget.isSearchingInProgress
                        ? null
                        : () {
                            showTooltip();
                            widget.onSelectionChanged(filter);
                          },
                    backgroundColor: isSelected
                        ? appTheme().primaryColorLight
                        : Colors.white,
                    child: Text(
                      getFilterIconText(filter),
                      style: TextStyle(
                        color: isSelected
                            ? appTheme().primaryColor
                            : appTheme().primaryColorDark,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
