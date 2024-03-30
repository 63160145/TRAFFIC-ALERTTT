import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:traffic_base/styles/colors_theme.dart';
import 'package:traffic_base/styles/text_style.dart';
import 'map_route_polyline.dart';

class MapRouteSheet extends StatefulWidget {
  final String locationName;

  const MapRouteSheet({Key? key, required this.locationName}) : super(key: key);

  @override
  State<MapRouteSheet> createState() => _MapRouteSheetState();
}

class _MapRouteSheetState extends State<MapRouteSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Position? userPosition;

  late String mode;

  String? distanceCar;
  String? timeCar;
  String? distanceBike;
  String? timeBike;
  String? distanceWalk;
  String? timeWalk;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    getUserLocation();

    mode = 'driving';

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        String selectedMode = '';
        switch (_tabController.index) {
          case 0:
            selectedMode = 'driving';
            break;
          case 1:
            selectedMode = 'driving';
            break;
          case 2:
            selectedMode = 'walking';
            break;
        }
        if (selectedMode.isNotEmpty && userPosition != null) {
          getDistanceAndTime(selectedMode);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getUserLocation() async {
    var permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        print(
            'ตำแหน่งปัจจุบันที่ได้รับ: Lat: ${position.latitude}, Long: ${position.longitude}');
        setState(() {
          userPosition = position;
        });
        getDistanceAndTime(mode);
      } on LocationServiceDisabledException {
        Fluttertoast.showToast(
          msg: "บริการตำแหน่งถูกปิด กรุณาเปิดการใช้งาน",
          gravity: ToastGravity.BOTTOM,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "ไม่สามารถดึงตำแหน่งปัจจุบันได้: $e",
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  Future<void> getDistanceAndTime(String mode) async {
    if (userPosition == null) {
      print('ตำแหน่งปัจจุบันไม่มี');
      return;
    }

    String origin = '${userPosition!.latitude},${userPosition!.longitude}';
    String destination = widget.locationName;
    String apiKey = dotenv.env['GOOGLE_API_KEY'] ?? 'YOUR_FALLBACK_API_KEY';
    print('ปลายทาง: $destination');
    var response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=$origin&destinations=$destination&mode=$mode&key=$apiKey&language=th'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);

      print('Response for mode $mode: $data');

      if (data['rows'][0]['elements'][0]['status'] == 'OK') {
        String distance = data['rows'][0]['elements'][0]['distance']['text'];
        String duration = data['rows'][0]['elements'][0]['duration']['text'];

        // อัปเดตตัวแปรตามโหมดที่เลือก
        setState(
          () {
            if (mode == 'driving') {
              distanceCar = distance;
              timeCar = duration;
            } else if (mode == 'driving') {
              distanceBike = distance;
              timeBike = duration;
            } else if (mode == 'walking') {
              distanceWalk = distance;
              timeWalk = duration;
            }
          },
        );

        print('ระยะทาง: $distance');
        print('เวลา: $duration');
      } else {
        print(
            'Data for mode $mode is not OK: ${data['rows'][0]['elements'][0]['status']}');
      }
    } else {
      print(
          'Request for mode $mode failed with status: ${response.statusCode}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.91,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                gradient: ColorGradient.getGradient(),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 10, left: 30),
                  child: Text(
                    "เส้นทาง",
                    style: AppTextStyle.sarabun1(context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color.fromARGB(255, 0, 0, 0),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(80.0),
                  color: Colors.grey.shade100,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Color(0xFFABE9CD),
                unselectedLabelColor: Colors.grey.shade500,
                tabs: const [
                  Tab(icon: Icon(Icons.directions_car)),
                  Tab(icon: Icon(Icons.directions_bike)),
                  Tab(icon: Icon(Icons.directions_walk)),
                ],
                onTap: (index) {
                  setState(() {
                    if (index == 0) {
                      mode = 'driving';
                    } else if (index == 1) {
                      mode = 'driving';
                    } else if (index == 2) {
                      mode = 'walking';
                    }
                  });
                },
              ),
            ),
            SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.place_rounded),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        userPosition != null
                            ? "${userPosition!.latitude}, ${userPosition!.longitude}"
                            : 'กำลังดึงตำแหน่งปัจจุบัน...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.sarabun2_1(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.place_rounded),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.locationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.sarabun2_1(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'ระยะเวลาการเดินทาง',
                    style: AppTextStyle.sarabun6(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildTabContent('driving', timeCar, distanceCar),
                  buildTabContent('driving', timeCar, distanceCar),
                  buildTabContent('walking', timeWalk, distanceWalk),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabContent(String mode, String? time, String? distance) {
    return Padding(
      padding: EdgeInsets.only(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
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
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 20,
                          top: 15,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              time ?? 'กำลังคำนวณ...',
                              style: AppTextStyle.roboto7(context),
                            ),
                            Text(
                              distance ?? 'กำลังคำนวณ...',
                              style: AppTextStyle.sarabun5(context),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.only(right: 15),
                        child: ElevatedButton(
                          onPressed: () {
                            if (userPosition != null) {
                              print(
                                  'User position is: ${userPosition!.latitude}, ${userPosition!.longitude}');
                              print(
                                  'Destination location is: ${widget.locationName}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapPolyline(
                                    userLocation: userPosition!,
                                    destinationLocation: widget.locationName,
                                    //time:timeCar,
                                  ),
                                ),
                              );
                            } else {
                              // ตำแหน่งผู้ใช้ไม่มีค่า, แสดงข้อความแจ้ง
                              Fluttertoast.showToast(
                                msg: 'กำลังดึงตำแหน่งปัจจุบัน...',
                                gravity: ToastGravity.CENTER,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            backgroundColor: Colors.lightGreenAccent.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Container(
                            width: 25,
                            height: 40,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
