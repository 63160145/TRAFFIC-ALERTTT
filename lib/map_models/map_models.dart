import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:traffic_base/services/database.dart';

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

//MapStyle
  @override
  void initState() {
    super.initState();

    _initializeMap();
    _getCurrentLocation();
    _getUserLocation();
    _startLocationUpdates();
  }

  Future<void> _initializeMap() async {
    await loadMapTheme();
    _buildMarkers();
  }

  Future<void> loadMapTheme() async {
    final String data = await DefaultAssetBundle.of(context)
        .loadString('assets/map_theme/map_standard.json');
    setState(() {
      mapTheme = data;
    });
  }

  Future<void> _startLocationUpdates() async {
    await _getCurrentLocation();
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        currentLocation = position;
      });
    });
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
      String? placeName =
          await getPlaceName(position.latitude, position.longitude);
      setState(() {
        _userLocation = userLocation;
      });
      mapController.animateCamera(CameraUpdate.newLatLng(userLocation));

      if (placeName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.white.withOpacity(0.9),
            content: Text(
              'Location: $placeName',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.white.withOpacity(0.9),
            content: const Text(
              'Location: Unknown',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }
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
                zoom: 15,
              ),
              //MapStyle
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                zoomController = MapZoomController(mapController: controller);

                if (mapTheme.isNotEmpty) {
                  controller.setMapStyle(mapTheme);
                }
              },
              //hide button zoom map orginal
              zoomControlsEnabled: false,
              compassEnabled: false,
              markers: combinedMarkers,
            ),
          ),
        ),
        Positioned(
          top: 30,
          right: 15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'search_bt',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled:
                        true, // Allow the bottom sheet to be expanded
                    builder: (BuildContext context) => Container(
                      height: MediaQuery.of(context).size.height *
                          0.91, // ClipRRect to round the corners
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
                iconData: Icons.search_rounded,
              ),
            ],
          ),
        ),
        Positioned(
          top: 560,
          right: 15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'userlocation',
                onPressed: _getUserLocation,
                iconData: Icons.near_me_rounded,
              ),
            ],
          ),
        ),
        Positioned(
          top: 620,
          right: 15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'zoomin',
                onPressed: () {
                  zoomController.zoomIn();
                },
                iconData: Icons.add,
              ),
            ],
          ),
        ),
        Positioned(
          top: 680,
          right: 15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'zoomin',
                onPressed: () {
                  zoomController.zoomOut();
                },
                iconData: Icons.remove,
              ),
            ],
          ),
        ),
        Positioned(
          top: 680,
          right: 15,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'zoomin',
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

  void _buildMarkers() async {
    List<String> collections = [
      'markers/traffic-sign-blue/signs_blue',
      'markers/traffic-sign-construction-warning/signs_c-warning',
      'markers/traffic-sign-guide/signs_guide',
      'markers/traffic-sign-red/signs_red',
      'markers/traffic-sign-warning/signs_warning'
    ];

    for (String collectionId in collections) {
      List<DocumentSnapshot> markerData =
          await Database.getData(path: collectionId);
      _processMarkerData(collectionId, markerData);
    }

    _mergeCurrentLocationWithMarkers();

    setState(() {});
  }

  void _processMarkerData(
      String collectionId, List<DocumentSnapshot> documents) {
    documents.forEach((doc) {
      try {
        dynamic locationData = (doc.data() as Map<String, dynamic>)['location'];
        String? name = (doc.data() as Map<String, dynamic>)['name'] as String?;
        String? description =
            (doc.data() as Map<String, dynamic>)['description'] as String?;

        if (locationData != null && name != null) {
          // If locationData is a single GeoPoint
          if (locationData is GeoPoint) {
            BitmapDescriptor? markerColor = _getMarkerColor(collectionId);
            if (markerColor != null) {
              Marker marker = Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(locationData.latitude, locationData.longitude),
                infoWindow: InfoWindow(
                  title: "ป้าย $name",
                  snippet: description ?? "ไม่มีข้อความเพิ่มเติม",
                ),
                icon: markerColor,
              );
              markers.add(marker);
            } else {
              print("Marker color not found for collectionId: $collectionId");
            }
          }
          // If locationData is a list of GeoPoint objects
          else if (locationData is List<dynamic>) {
            for (var location in locationData) {
              if (location is GeoPoint) {
                BitmapDescriptor? markerColor = _getMarkerColor(collectionId);
                if (markerColor != null) {
                  Marker marker = Marker(
                    markerId: MarkerId(doc.id + location.hashCode.toString()),
                    position: LatLng(location.latitude, location.longitude),
                    infoWindow: InfoWindow(
                      title: "ป้าย $name",
                      snippet: description ?? "",
                    ),
                    icon: markerColor,
                  );
                  markers.add(marker);
                } else {
                  print(
                      "Marker color not found for collectionId: $collectionId");
                }
              } else {
                print("Invalid location data element: ${location.runtimeType}");
              }
            }
          } else {
            print("Invalid location data format");
          }
        } else {
          print("Invalid marker data: document ${doc.id}");
        }
      } catch (e) {
        print("Error processing marker data: $e");
      }
    });
  }

  BitmapDescriptor? _getMarkerColor(String collectionId) {
    switch (collectionId) {
      case 'markers/traffic-sign-blue/signs_blue':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'markers/traffic-sign-construction-warning/signs_c-warning':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'markers/traffic-sign-guide/signs_guide':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'markers/traffic-sign-red/signs_red':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'markers/traffic-sign-warning/signs_warning':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow);
      default:
        return null;
    }
  }
}
