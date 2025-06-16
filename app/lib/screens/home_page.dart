import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:flutter/material.dart';
import 'package:kids_info_app/data/constants.dart';
import 'package:kids_info_app/data/enum.dart';
import 'package:kids_info_app/data/preferences.dart';
import 'package:kids_info_app/helpers/hospital_search_helper.dart';
import 'package:kids_info_app/helpers/location_helper.dart';
import 'package:kids_info_app/helpers/toast_helper.dart';
import 'package:kids_info_app/helpers/user_helper.dart';
import 'package:kids_info_app/screens/info_page.dart';
import 'package:kids_info_app/theme/style.dart';
import 'package:kids_info_app/widgets/background.dart';
import 'package:kids_info_app/widgets/floating_button_section.dart';
import 'package:kids_info_app/widgets/home_drawer.dart';
import 'package:kids_info_app/widgets/hospital_slider_panel.dart';
import 'package:kids_info_app/widgets/place_search_bar.dart';
import 'package:kids_info_app/data/place.dart';
import 'package:kids_info_app/data/hospital.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart' as loc;
import 'package:mutex/mutex.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variables
  HospitalSearchResult _searchResult = HospitalSearchResult(0, []);
  HospitalTypeFilter _typeFilter = HospitalTypeFilter.allType;
  HospitalStatusFilter _statusFilter = HospitalStatusFilter.allStatus;
  List<Hospital> _visibleHospitals = [];
  List<Marker> _markers = [];
  List<CustomOverlay> _labels = [];
  String _focusedHospitalId = '';
  // Key and controllers
  final GlobalKey _kakaoMapKey = GlobalKey();
  final PanelController _sliderPanelController = PanelController();
  final ScrollController _sliderPanelScrollController = ScrollController();
  KakaoMapController? _mapController;
  // Flags
  bool _areHospitalsVisible = true;
  bool _isSearchingInProgress = false;
  bool _isLocatingInProgress = false;
  bool _mapDragDirty = false;
  // Search task management
  final Mutex _searchMutex = Mutex();
  bool _searchQueued = false;

  String _getLabelColorWithOperatingStatus(Hospital hospital) {
    // Mark gray if hospital is not operating currently
    String color = 'white';
    if (hospital.operatingStatus == HospitalOperatingStatus.notOpenedToday ||
        hospital.operatingStatus == HospitalOperatingStatus.finished) {
      color = '#D3D3D3'; // light gray
    }
    return color;
  }

  // border: 2px solid $borderColorHex;
  String _getLabelContent(Place place, String backgroundColor, bool focus) {
    String borderColorHex = appTheme().primaryColorDark.toHexColor();
    return '<div class="label" style="'
        '     background-color: $backgroundColor; '
        '     padding: 6px; '
        '     border-radius: 8px;'
        '     ${focus ? 'font-weight: bold;' : ''}'
        '     border: 1px solid $borderColorHex;">'
        '     <span class="center">${place.name}</span>'
        '</div>';
  }

  bool canShowLabels() {
    int? currentLevel = Preferences.getInstance().getInt(prefStartLevelKey);
    return currentLevel == null ||
        (currentLevel != null && currentLevel <= defaultMapLevel);
  }

  void _updateHospitalListAndMarkers() {
    List<Hospital> visibleHospitals = [];

    if (_areHospitalsVisible && _searchResult.hospitals.isNotEmpty) {
      // Show warning toast if needed
      if (_searchResult.totalResultCount > 0 &&
          _searchResult.totalResultCount > _searchResult.hospitals.length) {
        showToast('현 지도에 병원이 너무 많아 일부만 표시됩니다.');
      }

      // Deep copy hospitals according to type
      visibleHospitals = _searchResult.hospitals.toList();

      // Sort hospitals with latitude (y) position
      if (_statusFilter != HospitalStatusFilter.openNow) {
        visibleHospitals.sort((a, b) {
          if (a.latLng.latitude > b.latLng.latitude) {
            return -1; // a comes before b
          } else if (a.latLng.latitude < b.latLng.latitude) {
            return 1; // b comes before a
          }
          return 0;
        });
      }
    }

    // Update markers and labels in reverse order from marker
    var markers = _markers.where((Marker marker) {
      return marker.markerId == myLocationId ||
          marker.markerId == searchLocationId;
    }).toList();
    var labels = _labels.where((CustomOverlay label) {
      return label.customOverlayId == myLocationId ||
          label.customOverlayId == searchLocationId;
    }).toList();
    bool showLabel = canShowLabels();
    for (Hospital info in visibleHospitals.reversed) {
      // Marker
      markers.add(Marker(
          markerId: info.id,
          latLng: info.latLng,
          width: 36,
          height: 45,
          markerImageSrc: imageSrcHospital));
      // Label
      if (showLabel) {
        String color = _getLabelColorWithOperatingStatus(info);
        labels.add(CustomOverlay(
            customOverlayId: info.id,
            // Deep copy LatLng to adjust position when overlaps
            latLng: LatLng(info.latLng.latitude, info.latLng.longitude),
            content: _getLabelContent(info, color, false),
            yAnchor: labelYAnchor));
      }
    }

    // Update label latitude if needed not to make overlap
    if (labels.length > 1) {
      labels.sort((a, b) {
        if (a.latLng.latitude < b.latLng.latitude) {
          return -1; // a comes before b
        } else if (a.latLng.latitude > b.latLng.latitude) {
          return 1; // b comes before a
        }
        return 0;
      });
      for (int i = 0; i < labels.length - 1; i++) {
        for (int j = i + 1; j < labels.length; j++) {
          if (labels[j].latLng.latitude - labels[i].latLng.latitude >
              labelPlacementLatEps) {
            break;
          } else if ((labels[j].latLng.longitude - labels[i].latLng.longitude)
                  .abs() <
              labelPlacementLngEps) {
            labels[j].latLng.latitude =
                labels[i].latLng.latitude + labelPlacementLatEps;
          }
        }
      }
    }

    // Assign to state
    setState(() {
      _visibleHospitals = visibleHospitals;
      _markers = markers;
      _labels = labels;
    });
  }

  Future<void> _fetchHospitalsInBounds() async {
    // Prevent too frequent search
    if (_searchQueued) {
      return;
    }
    if (_searchMutex.isLocked) {
      _searchQueued = true;
    }
    await _searchMutex.protect(() async {
      _searchQueued = false;

      setState(() {
        // Start progress ring
        _isSearchingInProgress = true;

        // Close slider panel
        _sliderPanelController.close();
      });

      HospitalSearchResult searchResult = HospitalSearchResult(0, []);

      try {
        var bounds = await _mapController?.getBounds();

        if (_areHospitalsVisible && bounds != null) {
          // Get top margin
          double topMarginProportion = 0.0;
          if (_kakaoMapKey.currentContext != null) {
            RenderBox kakaoMapBox =
                _kakaoMapKey.currentContext?.findRenderObject() as RenderBox;
            topMarginProportion = searchTopMargin / kakaoMapBox.size.height;
          }

          // Get bounds regarding bounds
          double swy = bounds.getSouthWest().latitude;
          double nex = bounds.getNorthEast().longitude;
          double ney = bounds.getNorthEast().latitude;
          ney -= topMarginProportion * (ney - swy);
          LatLngBounds searchBounds =
              LatLngBounds(bounds.getSouthWest(), LatLng(ney, nex));

          // Search hospitals
          searchResult = await searchHospitalsInBounds(
                  searchBounds, _typeFilter, _statusFilter)
              .timeout(const Duration(seconds: hospitalSearchTimeout),
                  onTimeout: () {
            showToast('검색 서버 오류가 발생했습니다.');
            return HospitalSearchResult(0, []);
          });
        }
      } finally {
        setState(() {
          // Update search result
          _searchResult = searchResult;

          // Stop progress ring
          _isSearchingInProgress = false;
        });

        /// Show hide warning toast
        /// This logic shouldn't be in _updateHospitalListAndMarker
        /// as it is called without actual searching in some cases
        if (!_areHospitalsVisible) {
          showToast('현재 숨김 상태입니다.\n병원을 보시려면 숨김을 해제해주세요.');
        }

        // Update list and markers
        _updateHospitalListAndMarkers();
      }
    });
  }

  void _locateMeAndFetchHospitals() {
    setState(() {
      // Highlight locating button
      _isLocatingInProgress = true;
    });

    // Get location
    loc.Location().getLocation().then((currentLoc) {
      if (currentLoc.latitude == null || currentLoc.longitude == null) {
        print('Current location is empty');
        return;
      }

      var center = LatLng(currentLoc.latitude!, currentLoc.longitude!);

      // Update preference - start location
      var prefs = Preferences.getInstance();
      prefs.setDouble(prefStartLatKey, center.latitude);
      prefs.setDouble(prefStartLngKey, center.longitude);

      setState(() {
        // Unhighlight locating button
        _isLocatingInProgress = false;

        // Update map center
        _mapController?.setCenter(center);

        // Fetch hospitals
        _fetchHospitalsInBounds().then((_) {
          setState(() {
            // Update location marker
            _markers.removeWhere((Marker marker) {
              return marker.markerId == myLocationId;
            });
            _markers.add(Marker(
                markerId: myLocationId,
                width: 36,
                height: 36,
                markerImageSrc: imageSrcMyLocation,
                latLng: center));
          });
        });
      });
    });
  }

  void _searchPlaceAndFetchHospitals(Place place) {
    setState(() {
      // Update map center and zoom
      _mapController?.setCenter(place.latLng);
      _mapController?.setLevel(searchMapLevel);

      // Fetch hospitals
      _fetchHospitalsInBounds().then((_) {
        setState(() {
          // Update marker
          _markers.removeWhere((Marker marker) {
            return marker.markerId == searchLocationId;
          });
          _markers.insert(
              0,
              Marker(
                  markerId: searchLocationId,
                  width: 36,
                  height: 36,
                  markerImageSrc: imageSrcPlace,
                  latLng: place.latLng));
        });
      });
    });
  }

  void _focusHospital(String hospitalId) {
    // Remove or replace old focus label
    int oldHospitalIndex = _visibleHospitals
        .indexWhere((hospital) => hospital.id == _focusedHospitalId);
    if (oldHospitalIndex != -1) {
      Hospital hospital = _visibleHospitals[oldHospitalIndex];
      int labelIndex =
          _labels.indexWhere((label) => label.customOverlayId == hospital.id);
      if (labelIndex != -1) {
        setState(() {
          CustomOverlay oldLabel = _labels.removeAt(labelIndex);
          if (canShowLabels()) {
            _labels.add(CustomOverlay(
                customOverlayId: oldLabel.customOverlayId,
                latLng: oldLabel.latLng,
                content: _getLabelContent(hospital,
                    _getLabelColorWithOperatingStatus(hospital), false),
                yAnchor: labelYAnchor));
          }
        });
      }
    }

    int newFocusIndex =
        _visibleHospitals.indexWhere((hospital) => hospital.id == hospitalId);
    if (newFocusIndex != -1) {
      Hospital hospital = _visibleHospitals[newFocusIndex];

      setState(() {
        // Update focus id
        _focusedHospitalId = hospital.id;

        // Move to location
        _mapController?.setCenter(hospital.latLng);
      });

      // Replace new focus label
      int labelIndex =
          _labels.indexWhere((label) => label.customOverlayId == hospital.id);
      String id = hospital.id;
      LatLng latLng = hospital.latLng;
      setState(() {
        if (labelIndex != -1) {
          CustomOverlay oldLabel = _labels.removeAt(labelIndex);
          id = oldLabel.customOverlayId;
          latLng = oldLabel.latLng;
        }
        _labels.add(CustomOverlay(
            customOverlayId: id,
            latLng: latLng,
            content: _getLabelContent(
                hospital, _getLabelColorWithOperatingStatus(hospital), true),
            yAnchor: labelYAnchor));
      });
    }
  }

  void _onMarkerlLabelTap(String hospitalId) {
    int index =
        _visibleHospitals.indexWhere((hospital) => hospital.id == hospitalId);

    if (index != -1) {
      // Open and scroll slider panel
      if (_sliderPanelController.isPanelClosed) {
        _sliderPanelController.open();
      }
      double position = index * sliderPanelListTileHeight;
      _sliderPanelScrollController.animateTo(position,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

      // Update marker and list selection
      _focusHospital(hospitalId);
    }
  }

  void _updateHospitalWithId(String hospitalId) {
    getHospitalWithId(hospitalId).then((hospital) {
      if (hospital == null) {
        return;
      }
      var oldResult = _searchResult;
      int totalResultCount = oldResult.totalResultCount;
      var hospitals = oldResult.hospitals;

      // Update array
      int index = hospitals.indexWhere((element) => element.id == hospitalId);
      if (index < 0) {
        return;
      }
      hospitals[index] = hospital;

      setState(() {
        // Update map
        HospitalSearchResult newResult =
            HospitalSearchResult(totalResultCount, hospitals);
        _searchResult = newResult;
      });

      // Update list and markers
      _updateHospitalListAndMarkers();
    });
  }

  @override
  void initState() {
    // Create user id if needed
    getOrCreateUserId();

    // Locate me and fetch hospitals
    isLocationPermissionGranted().then((isGranted) {
      if (isGranted) {
        _locateMeAndFetchHospitals();
      }
    });

    super.initState();

    // Enable in-app review
    AdvancedInAppReview()
        .setMinDaysBeforeRemind(7)
        .setMinDaysAfterInstall(2)
        .setMinLaunchTimes(2)
        .setMinSecondsBeforeShowDialog(4)
        .monitor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme().primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: PlaceSearchBar(
          width: MediaQuery.of(context).size.width,
          height: searchBarHeight,
          onSelectPlace: (Place place) {
            _searchPlaceAndFetchHospitals(place);
          },
        ),
        titleSpacing: 0,
      ),
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Map
            BackgroundImage(
              mapWidget: KakaoMap(
                key: _kakaoMapKey,
                markers: _markers,
                customOverlays: _labels,
                onMapCreated: ((controller) {
                  _mapController = controller;

                  // Load start location from shared preference
                  var prefs = Preferences.getInstance();
                  double? startLat = prefs.getDouble(prefStartLatKey);
                  double? startLng = prefs.getDouble(prefStartLngKey);
                  int? startLevel = prefs.getInt(prefStartLevelKey);
                  if (startLat != null &&
                      startLng != null &&
                      startLevel != null) {
                    _mapController?.setCenter(LatLng(startLat, startLng));
                    _mapController?.setLevel(startLevel);
                  } else {
                    _mapController?.setCenter(LatLng(defaultLat, defaultLng));
                    _mapController?.setLevel(defaultMapLevel);
                  }

                  // Fetch hospitals
                  _fetchHospitalsInBounds();
                }),
                onDragChangeCallback:
                    (LatLng latLng, int zoomLevel, DragType dragType) {
                  var prefs = Preferences.getInstance();
                  prefs.setDouble(prefStartLatKey, latLng.latitude);
                  prefs.setDouble(prefStartLngKey, latLng.longitude);
                  prefs.setInt(prefStartLevelKey, zoomLevel);

                  // Mark dirty
                  setState(() {
                    _mapDragDirty = true;
                  });
                },
                onZoomChangeCallback: (int zoomLevel, ZoomType zoomType) {
                  var prefs = Preferences.getInstance();
                  prefs.setInt(prefStartLevelKey, zoomLevel);

                  // Mark dirty
                  setState(() {
                    _mapDragDirty = true;
                  });
                },
                onCameraIdle: (LatLng latLng, int zoomLevel) {
                  if (_mapDragDirty) {
                    _fetchHospitalsInBounds().then((value) {
                      // Clean dirty
                      setState(() {
                        _mapDragDirty = false;
                      });
                    });
                  }
                },
                onMarkerTap: (String markerId, LatLng latLng, int zoomLevel) {
                  _onMarkerlLabelTap(markerId);
                },
                onCustomOverlayTap: (String customOverlayId, LatLng latLng) {
                  _onMarkerlLabelTap(customOverlayId);
                },
              ),
            ),
            // App bar and floating buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: FloatingButtonSection(
                    isSearchingInProgress: _isSearchingInProgress,
                    isLocatingInProgress: _isLocatingInProgress,
                    onRefreshPressed: () {
                      _fetchHospitalsInBounds();
                    },
                    onLocateMe: () {
                      requestLocationPermission().then((isGranted) {
                        if (isGranted) {
                          _locateMeAndFetchHospitals();
                        } else {
                          showPermissionDeniedDialog(context);
                        }
                      });
                    },
                    onFilterChanged: (HospitalTypeFilter typeFilter,
                        HospitalStatusFilter statusFilter) {
                      setState(() {
                        // Close slider panel
                        _sliderPanelController.close();

                        // Update filter
                        _typeFilter = typeFilter;
                        _statusFilter = statusFilter;
                      });

                      // Update hospitals
                      _fetchHospitalsInBounds();
                    },
                    onShowHospitalsChanged: (bool show) {
                      setState(() {
                        _areHospitalsVisible = show;
                      });

                      // Update hospitals
                      if (show) {
                        _fetchHospitalsInBounds();
                      } else {
                        // Close slider panel
                        _sliderPanelController.close();

                        /// _updateHospitalListAndMarkers is necessary for hiding
                        /// instead of just using _fetchHospitalsInBounds
                        /// to make sure of clearing remaining markers.
                        _updateHospitalListAndMarkers();
                      }
                    },
                  ),
                ),
              ],
            ),
            // Slider panel
            HospitalSliderPanel(
                hospitals: _visibleHospitals,
                panelController: _sliderPanelController,
                scrollController: _sliderPanelScrollController,
                focusedHospitalId: _focusedHospitalId,
                onListItemTapped: _focusHospital,
                onDetailPageBackButtonPressed: () {
                  // Refresh hospital information
                  if (_focusedHospitalId.isNotEmpty) {
                    _updateHospitalWithId(_focusedHospitalId);
                  }
                }),
          ],
        ),
      ),
    );
  }
}
