import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class Place {
  String id;
  String name;
  String address;
  LatLng latLng;

  Place(this.id, this.name, this.address, this.latLng);
}

class PlaceSearchResult {
  int totalResultCount;
  List<Place> places;

  PlaceSearchResult(this.totalResultCount, this.places);
}
