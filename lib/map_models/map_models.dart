import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collection/collection.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:traffic_base/services/database.dart';

import '../styles/colors_theme.dart';
import '../styles/custom_fab.dart';

import 'widgets/search/map_search.dart';
import 'zoom_controller.dart';

class MapScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _pGooglePlex = LatLng(13.2891, 100.9244);

  String mapTheme = '';

  late GoogleMapController mapController;
  late MapZoomController zoomController;

  Position? currentLocation;

  // ignore: unused_field
  late LatLng _userLocation;

  bool mapToggle = false;

  List<Marker> markers = [];

  Set<Marker> combinedMarkers = {};

  String? selectedCategory;

  bool showTrafficSigns = false;

  Timer? textSwitchTimer;
  String alertText = 'Traffic Alert';

  Set<Marker> userMarkers = {};

  @override
  void initState() {
    super.initState();

    _initializeMap();
    _getCurrentLocation();
    //_getUserLocation();
    _startLocationUpdates();

    textSwitchTimer = Timer.periodic(Duration(seconds: 10), (Timer t) {
      setState(() {
        alertText =
            alertText == 'Traffic Alert' ? 'Traffic Signs' : 'Traffic Alert';
      });
    });
  }

  @override
  void dispose() {
    textSwitchTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _loadMapTheme();
  }

  void toggleTrafficSignsVisibility() {
    setState(() {
      showTrafficSigns = !showTrafficSigns;
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    mapController?.setMapStyle(mapTheme);
    zoomController = MapZoomController(mapController: controller);
  }

  Future<void> _loadMapTheme() async {
    final String data = await DefaultAssetBundle.of(context)
        .loadString('assets/map_theme/map_standard.json');
    setState(() {
      mapTheme = data;
      print('Map theme loaded: $mapTheme');
    });
  }

  Future<void> _startLocationUpdates() async {
    await _getCurrentLocation();
    Geolocator.getPositionStream().listen(
      (Position position) {
        setState(() {
          currentLocation = position;
        });
        // อัปเดตตำแหน่งเครื่องหมายหรือดำเนินการอื่น ๆ
        _mergeCurrentLocationWithMarkers();
        if (currentLocation != null) {
          LatLng Location =
              LatLng(currentLocation!.latitude, currentLocation!.longitude);
          mapController.animateCamera(CameraUpdate.newLatLng(Location));
        }
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    Position res = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLocation = res;
      mapToggle = true;
    });
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng userLocation = LatLng(position.latitude, position.longitude);
      // Create or update the user location marker
      final Marker userLocationMarker = Marker(
        markerId: const MarkerId("userLocationMarker"),
        position: userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      );

      setState(() {
        _userLocation = userLocation;
        // Replace or add the user marker to its own dedicated Set
        //userMarkers.clear(); // Clear previous marker
        //userMarkers.add(userLocationMarker); // Add the new marker
      });

      mapController.animateCamera(CameraUpdate.newLatLng(userLocation));
    } catch (error) {
      print("Failed to get location: $error");
    }
  }

  Future<String?> getPlaceName(double latitude, double longitude) async {
    final apiKey = dotenv.env['GOOGLE_API_KEY'] ?? 'YOUR_FALLBACK_API_KEY';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey&language=th';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'];
      if (results.isNotEmpty) {
        return results[0]['formatted_address'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: 1000,
            height: 1000,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pGooglePlex,
                zoom: 14,
              ),
              //MapStyle
              onMapCreated: _onMapCreated,
              zoomControlsEnabled: false,
              compassEnabled: false,
              markers: userMarkers.union(combinedMarkers),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.09,
          left: MediaQuery.of(context).size.width * 0.05,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 175,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [Color(0xFF52B8CF), Color(0xFFABE9CD)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    print('Button tapped');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.location_solid, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        alertText,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.5,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  splashColor: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        //1
        Positioned(
          top: MediaQuery.of(context).size.height * 0.16,
          right: MediaQuery.of(context).size.width * 0.05,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: toggleTrafficSignsVisibility,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: ColorGradient.getGradient().colors.first,
                      ),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  splashColor: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        //2
        Positioned(
          top: MediaQuery.of(context).size.height * 0.23,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AnimatedOpacity(
            opacity: showTrafficSigns ? 1.0 : 0.0,
            duration:
                Duration(milliseconds: 500), // ควบคุมความเร็วของ animation
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => onCategorySelected(
                        'markers/traffic-sign-red/signs_red'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.red),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        //3
        Positioned(
          top: MediaQuery.of(context).size.height * 0.30,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AnimatedOpacity(
            opacity: showTrafficSigns ? 1.0 : 0.0,
            duration: Duration(milliseconds: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => onCategorySelected(
                        'markers/traffic-sign-blue/signs_blue'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.blue.shade900),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        //4
        Positioned(
          top: MediaQuery.of(context).size.height * 0.37,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AnimatedOpacity(
            opacity: showTrafficSigns ? 1.0 : 0.0,
            duration: Duration(milliseconds: 700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => onCategorySelected(
                        'markers/traffic-sign-warning/signs_warning'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.amber),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        //5
        Positioned(
          top: MediaQuery.of(context).size.height * 0.44,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AnimatedOpacity(
            opacity: showTrafficSigns ? 1.0 : 0.0,
            duration: Duration(milliseconds: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => onCategorySelected(
                        'markers/traffic-sign-guide/signs_guide'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.blue),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        //6
        Positioned(
          top: MediaQuery.of(context).size.height * 0.51,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AnimatedOpacity(
            opacity: showTrafficSigns ? 1.0 : 0.0,
            duration: Duration(milliseconds: 900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => onCategorySelected(null),
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.grey.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill,
                            color: ColorGradient.getGradient().colors.last),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        //7
        Positioned(
          top: MediaQuery.of(context).size.height * 0.58,
          right: MediaQuery.of(context).size.width * 0.05,
          child: AnimatedOpacity(
            opacity: showTrafficSigns ? 1.0 : 0.0,
            duration: Duration(milliseconds: 1000),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => onCategorySelected(
                        'markers/traffic-sign-construction-warning/signs_c-warning'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.grey),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    splashColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        //-------------------------------------------------------------------
        Positioned(
          top: MediaQuery.of(context).size.height * 0.09,
          right: MediaQuery.of(context).size.width * 0.05,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'search_bt',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) => Container(
                      height: MediaQuery.of(context).size.height * 0.91,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ),
                      ),
                      child: MapLocationSearchSheet(
                          getUserLocation: _getUserLocation),
                    ),
                  );
                },
                iconData: CupertinoIcons.search,
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.76,
          right: MediaQuery.of(context).size.width * 0.05,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'userlocation',
                onPressed: _getUserLocation,
                iconData: CupertinoIcons.location,
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.83,
          right: MediaQuery.of(context).size.width * 0.05,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'zoomin',
                onPressed: () {
                  zoomController.zoomIn();
                },
                iconData: CupertinoIcons.add,
              ),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.90,
          right: MediaQuery.of(context).size.width * 0.05,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'zoomout',
                onPressed: () {
                  zoomController.zoomOut();
                },
                iconData: Icons.remove,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mergeCurrentLocationWithMarkers() {
    setState(() {
      if (currentLocation != null) {
        combinedMarkers.add(
          Marker(
            markerId: const MarkerId("_currentLocation"),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            position: LatLng(
              currentLocation!.latitude,
              currentLocation!.longitude,
            ),
          ),
        );
      }
      combinedMarkers.addAll(markers);
    });
  }

  void onCategorySelected(String? category) {
    print("Category selected: $category");
    setState(() {
      selectedCategory = category;
      combinedMarkers.clear();
      markers.clear();
      _buildMarkers(category: selectedCategory);
    });
  }

  void _buildMarkers({String? category}) async {
    List<String> collections;
    if (category != null) {
      collections = [category];
    } else {
      collections = [
        'markers/traffic-sign-blue/signs_blue',
        'markers/traffic-sign-construction-warning/signs_c-warning',
        'markers/traffic-sign-guide/signs_guide',
        'markers/traffic-sign-red/signs_red',
        'markers/traffic-sign-warning/signs_warning',
      ];
    }
    combinedMarkers.clear();

    for (String collectionId in collections) {
      List<DocumentSnapshot> markerData =
          await Database.getData(path: collectionId);
      _processMarkerData(collectionId, markerData);
    }

    //_mergeCurrentLocationWithMarkers();

    setState(() {});
  }

  void _processMarkerData(
      String collectionId, List<DocumentSnapshot> documents) async {
    var markerIconCache = <String, BitmapDescriptor>{};
    var newMarkers = Set<Marker>();

    for (var doc in documents) {
      try {
        var data = doc.data() as Map<String, dynamic>;
        var name = data['name'] as String?;
        var description = data['description'] as String?;
        var iconUrl = data['iconUrl'] as String?;
        List<dynamic> locations = data['location']; // location is an array

        if (name != null && iconUrl != null && locations is List) {
          BitmapDescriptor markerIcon;

          if (markerIconCache.containsKey(iconUrl)) {
            markerIcon = markerIconCache[iconUrl]!;
          } else {
            markerIcon = await getMarkerBitmapFromUrl(iconUrl);
            markerIconCache[iconUrl] = markerIcon;
          }

          // Create a marker for each GeoPoint in the array
          for (var geoPoint in locations) {
            if (geoPoint is GeoPoint) {
              if (selectedCategory == null ||
                  collectionId.contains(selectedCategory!)) {
                newMarkers.add(Marker(
                  markerId: MarkerId(doc.id + geoPoint.hashCode.toString()),
                  position: LatLng(geoPoint.latitude, geoPoint.longitude),
                  infoWindow: InfoWindow(title: name, snippet: description),
                  icon: markerIcon,
                ));
              }
            }
          }
        }
      } catch (e) {
        print("Error processing document ${doc.id}: $e");
      }
    }

    if (!SetEquality().equals(combinedMarkers, newMarkers)) {
      setState(() {
        combinedMarkers = newMarkers;
      });
    }
  }

  void _createMarkerFromGeoPoint(String docId, GeoPoint geoPoint, String name,
      String? description, String iconUrl) async {
    var markerBitmap = await getMarkerBitmapFromUrl(iconUrl);
    setState(() {
      markers.add(Marker(
        markerId: MarkerId(docId),
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        infoWindow: InfoWindow(title: name, snippet: description),
        icon: markerBitmap,
      ));
    });
  }

  Future<BitmapDescriptor> getMarkerBitmapFromUrl(String iconUrl) async {
    final http.Response response = await http.get(Uri.parse(iconUrl));
    final Uint8List markerImageBytes = response.bodyBytes;
    return BitmapDescriptor.fromBytes(markerImageBytes);
  }
}
