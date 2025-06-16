import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/place.dart';
import 'package:kids_info_app/helpers/kakao_search_helper.dart';
import 'package:kids_info_app/theme/style.dart';

class PlaceSearchBar extends StatefulWidget {
  final void Function(Place) onSelectPlace;
  final double width;
  final double height;

  const PlaceSearchBar({
    super.key,
    required this.width,
    required this.height,
    required this.onSelectPlace,
  });

  @override
  PlaceSearchBarState createState() => PlaceSearchBarState();
}

class PlaceSearchBarState extends State<PlaceSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Place> _places = [];

  Widget _buildDropdown() {
    if (_places.isEmpty) {
      return const SizedBox(
        child: ListTile(
          title: Text('검색 결과가 없습니다.'),
          textColor: Colors.black,
        ),
      );
    }

    return SizedBox(
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          itemCount: _places.length,
          itemExtent: searchDialogListTileHeight,
          itemBuilder: (context, index) {
            final place = _places[index];
            String tileText = place.address.isEmpty
                ? place.name
                : '${place.name} (${place.address})';
            return ListTile(
              title:
                  Text(tileText, overflow: TextOverflow.ellipsis, maxLines: 1),
              textColor: Colors.black,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
              selectedColor: appTheme().highlightColor,
              onTap: () {
                widget.onSelectPlace(place);
                // Hide dropdown dialog
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  // Method to show the dropdown as an overlay
  void _showDropdown() {
    double bottomMargin = MediaQuery.of(context).size.height -
        searchDialogPaddingTop -
        (_places.isEmpty ? searchDialogEmptyHeight : searchDialogMaxHeight);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: searchDialogPaddingLeft,
          top: searchDialogPaddingTop,
          right: searchDialogPaddingRight,
          bottom: bottomMargin,
        ),
        child: Material(
          color: Colors.white,
          child: _buildDropdown(),
        ),
      ),
    );
  }

  void _performSearch() async {
    if (_searchController.text.isNotEmpty) {
      PlaceSearchResult result =
          await kakaoSearchGeneralPlaces(_searchController.text);
      _places = result.places;
      _showDropdown();

      // Firebase logging
      try {
        FirebaseAnalytics.instance.logEvent(
            name: 'search_place', parameters: {'term': _searchController.text});
      } catch (e) {
        print('Firebase analytics: failed to log place search');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.only(left: 5.0, right: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: TextField(
                focusNode: _focusNode,
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                cursorColor: Colors.white60,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '소아과 진료 병의원 또는 장소 검색',
                  border: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    alignment: Alignment.centerRight,
                    onPressed: _performSearch,
                  ),
                  suffixIconColor: Colors.white,
                ),
                onSubmitted: (value) {
                  _performSearch();
                }),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
