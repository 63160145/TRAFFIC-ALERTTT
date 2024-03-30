import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traffic_base/map_models/widgets/polyline/map_durations.dart';
import 'package:traffic_base/styles/custom_fab.dart';
import 'package:traffic_base/styles/text_style.dart';

// ignore: unused_import
import 'map_polyline_cancel.dart';

class MapPolyline extends StatefulWidget {
  final Position userLocation;
  final String destinationLocation;

  const MapPolyline({
    Key? key,
    required this.userLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  State<MapPolyline> createState() => _MapPolylineState();
}

class _MapPolylineState extends State<MapPolyline> {
  static const LatLng _pGooglePlex = LatLng(13.2891, 100.9244);

  String mapTheme = '';

  late GoogleMapController mapController;

  // ignore: unused_field
  late LatLng _userLocation; //เก็บที่อยู่ปัจจุบัน

  // ignore: unused_field
  LatLng? _currentLocation;

  // ignore: unused_field
  late bool _isNavigationActive = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = <Polyline>{};

  late LatLng destinationLatLng;

  List<LatLng> routePoints = []; //ตัวแปรระยะทางจากผู้ใช้กับปลายทาง

  int _fabPressCount = 0;

  List<Direction> _directions = [];

  @override
  void initState() {
    super.initState();

    loadMapTheme();

    convertDestinationLocation().then((_) {
      _getDirections(
          LatLng(
            widget.userLocation.latitude,
            widget.userLocation.longitude,
          ),
          destinationLatLng);
    });

    destinationLatLng = LatLng(0.0, 0.0);

    Geolocator.getPositionStream().listen((Position position) {
      // อัปเดตตำแหน่งปัจจุบันของผู้ใช้
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // อัปเดตตำแหน่งกล้องแผนที่ไปยังตำแหน่งใหม่
      mapController.animateCamera(CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude)));
    });
  }

  Future<void> _getDirections(LatLng start, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&key=AIzaSyBCazeWB1DmiNcGqUmrzQ4sOdh47auHye0&language=th';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> routes = data['routes'];
        if (routes.isNotEmpty) {
          final List<dynamic> steps = routes[0]['legs'][0]['steps'];
          final List<Direction> directionsList =
              steps.map((step) => Direction.fromJson(step)).toList();
          setState(() {
            _directions = directionsList;
          });
        } else {
          throw Exception('No routes found for the given locations.');
        }
      } else {
        throw Exception('Failed to fetch directions');
      }
    } catch (e) {
      print('Error fetching directions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> convertDestinationLocation() async {
    try {
      // Convert the destinationLocation to a LatLng object
      destinationLatLng =
          await getLatLngFromAddress(widget.destinationLocation);

      // Convert LatLng to Position
      Position destinationPosition = Position(
        latitude: destinationLatLng.latitude,
        longitude: destinationLatLng.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      routePoints =
          await getRoutePoints(widget.userLocation, destinationPosition);

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('userPosition'),
            position: LatLng(
                widget.userLocation.latitude, widget.userLocation.longitude),
          ),
        );
        _markers.add(
          Marker(
            markerId: MarkerId('destinationPosition'),
            position: destinationLatLng,
          ),
        );
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            visible: true,
            points: routePoints,
            color: Colors.blue,
            width: 8,
            geodesic: true,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      });
    } catch (e) {
// Handle the error, e.g., by showing an alert to the user
      print('An error occurred while converting destination location: $e');
    }
  }

  Future<LatLng> getLatLngFromAddress(String address) async {
    // Replace with your actual address
    String encodedAddress = Uri.encodeComponent(address);

    // Replace with your actual API key
    String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? 'YOUR_FALLBACK_API_KEY';

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      // It's a good practice to check if 'results' is not empty to avoid errors
      if (json['results'].isNotEmpty) {
        final lat = json['results'][0]['geometry']['location']['lat'];
        final lng = json['results'][0]['geometry']['location']['lng'];
        return LatLng(lat, lng);
      } else {
        throw Exception('No results found for the given address.');
      }
    } else {
      throw Exception(
          'Failed to get latlng from address, status code: ${response.statusCode}');
    }
  }

  Future<List<LatLng>> getRoutePoints(
      Position start, Position destination) async {
    String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? 'YOUR_FALLBACK_API_KEY';
    String startCoordinates = '${start.latitude},${start.longitude}';
    String destinationCoordinates =
        '${destination.latitude},${destination.longitude}';

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startCoordinates&destination=$destinationCoordinates&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json['routes'].isNotEmpty) {
        List<LatLng> polylinePoints = [];
        final legs = json['routes'][0]['legs'];
        for (var leg in legs) {
          final steps = leg['steps'];
          for (var step in steps) {
            final stepPolyline = step['polyline']['points'];
            polylinePoints.addAll(decodePolyline(stepPolyline));
          }
        }
        return polylinePoints;
      } else {
        throw Exception('No routes found for the given locations.');
      }
    } else {
      throw Exception(
          'Failed to get directions, status code: ${response.statusCode}');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Future<void> loadMapTheme() async {
    final String data = await DefaultAssetBundle.of(context)
        .loadString('assets/map_theme/map_standard.json');
    setState(() {
      mapTheme = data;
    });
  }

  Future<LatLng> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng userLocation = LatLng(position.latitude, position.longitude);
      mapController.animateCamera(CameraUpdate.newLatLng(userLocation));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Location: ${userLocation.latitude}, ${userLocation.longitude}'),
        ),
      );
      return userLocation;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $error'),
        ),
      );
      // คืนค่าพิกัดมาตรฐานหรือ null ถ้าคุณไม่ต้องการ throw exception
      return LatLng(0.0, 0.0);
    }
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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pGooglePlex,
              zoom: 15,
            ),
            onMapCreated: onMapCreated,
            zoomControlsEnabled: false,
            compassEnabled: false,
            markers: Set.from(_markers),
            polylines: Set.from(_polylines),
            mapType: MapType.normal),
        Positioned(
          top: 170,
          right: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'sound',
                onPressed: () {},
                iconData: Icons.volume_up,
              ),
              SizedBox(
                height: 5,
              ),
              CustomFAB(
                heroTag: 'navigation',
                onPressed: onFabPressed,
                iconData: Icons.navigation,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 30,
          right: 20,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomFAB(
                heroTag: 'end',
                onPressed: () {
                  _showDirectionsPanel();
                },
                iconData: Icons.expand_less_rounded,
              ),

              /*CustomFAB(
                heroTag: 'end',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.24,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.0),
                            topRight: Radius.circular(30.0),
                          ),
                        ),
                        child: MapPolylineCancelSheet(),
                      );
                    },
                  );
                },
                iconData: Icons.expand_less_rounded,
              ),*/
            ],
          ),
        ),
        Positioned(
          child: Column(
            children: [
              Container(
                height: 150,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF52B8CF).withOpacity(0.5),
                      Color(0xFFABE9CD).withOpacity(0.5)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: Column(
            children: [
              Container(
                height: 80,
                width: 370,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_sharp,
                        size: 60,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(width: 30),
                      Text(
                        'ป้ายจราจร...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.sarabunPolyline(
                          context,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 170,
          left: 20,
          child: Column(
            children: [
              Container(
                height: 40,
                width: 135,
                decoration: BoxDecoration(
                  color: Colors.white /*.withOpacity(0.9)*/,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      spreadRadius: 0.0,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 15, top: 10),
                  child: Text(
                    '10 นาที | 5 กม.',
                    style: AppTextStyle.sarabunPolylineTime(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ฟังก์ชันสำหรับคำนวณค่าองศาที่กล้องควรหันไปในแต่ละจุดบนเส้นทาง
  double calculateCameraBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * math.pi / 180.0;
    double startLng = start.longitude * math.pi / 180.0;
    double endLat = end.latitude * math.pi / 180.0;
    double endLng = end.longitude * math.pi / 180.0;

    double y = math.sin(endLng - startLng) * math.cos(endLat);
    double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(endLng - startLng);
    double bearing = math.atan2(y, x);

    return bearing * (180.0 / math.pi);
  }

  void adjustCameraBearing(
      GoogleMapController controller, LatLng start, LatLng end) {
    double bearing = calculateCameraBearing(start, end);
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: start,
          zoom: 15,
          bearing: bearing,
          tilt: 45,
        ),
      ),
    );
  }

  void zoomIn() {
    mapController.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    mapController.animateCamera(CameraUpdate.zoomOut());
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    /* if (mapTheme.isNotEmpty) {
      controller.setMapStyle(mapTheme);
    }*/

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('userPosition'),
          position: LatLng(
              widget.userLocation.latitude, widget.userLocation.longitude),
        ),
      );
    });

    mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
      ),
    );

    // ปรับมุมมองของกล้องให้หันไปในทิศทางที่ต้องการ
    adjustCameraBearing(
        mapController,
        LatLng(widget.userLocation.latitude, widget.userLocation.longitude),
        destinationLatLng);
  }

  void onFabPressed() async {
    LatLng userLocation = await _getUserLocation();

    switch (_fabPressCount) {
      case 0:
        // ย้ายกล้องไปยังตำแหน่งผู้ใช้
        mapController.animateCamera(
          CameraUpdate.newLatLng(userLocation),
        );
        break;
      case 1:
        // ซูมเข้าไปที่ตำแหน่งผู้ใช้
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(userLocation, 17.0),
        );
        break;
      case 2:
        // ปรับทิศทางเข็มทิศ
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: userLocation,
              zoom: 19.0,
              bearing: 0.0,
              tilt: 45,
            ),
          ),
        );
        break;
    }
    _fabPressCount = (_fabPressCount + 1) % 3;
  }

  void _showDirectionsPanel() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            itemCount: _directions.length,
            itemBuilder: (context, index) {
              String descriptionWithoutHtml = _directions[index]
                  .description
                  .replaceAll(RegExp(r'<[^>]*>'), '');
              String maneuver = _directions[index].maneuver;
              return ListTile(
                leading: buildDirectionIcon(maneuver),
                title: Text(descriptionWithoutHtml),
              );
            },
          ),
        );
      },
    );
  }

  Icon buildDirectionIcon(String maneuver) {
    IconData iconData;
    switch (maneuver) {
      case 'turn-left':
        iconData = Icons.arrow_left;
        break;
      case 'turn-right':
        iconData = Icons.arrow_right;
        break;
      case 'turn-slight-left':
        iconData = Icons.subdirectory_arrow_left;
        break;
      case 'turn-slight-right':
        iconData = Icons.subdirectory_arrow_right;
        break;
      case 'merge':
        iconData = Icons.call_merge;
        break;
      case 'roundabout-left':
        iconData = Icons.rotate_left;
        break;
      case 'roundabout-right':
        iconData = Icons.rotate_right;
        break;
      case 'fork-left':
        iconData = Icons.call_split;
        break;
      case 'fork-right':
        iconData = Icons.call_split;
        break;
      case 'keep-left':
        iconData = Icons.arrow_left;
        break;
      case 'keep-right':
        iconData = Icons.arrow_right;
        break;
      case 'uturn-left':
        iconData = Icons.u_turn_left;
        break;
      case 'uturn-right':
        iconData = Icons.u_turn_right;
        break;
      default:
        iconData = Icons.error;
        break;
    }
    return Icon(iconData);
  }
}