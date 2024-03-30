import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/network_utility.dart';
import '../../../styles/colors_theme.dart';
import '../../../styles/text_style.dart';
import '../polyline/map_route_start.dart';
import 'autocomplate_prediction.dart';
import 'map_search_list.dart';
import 'place_auto_complate_response.dart';

class MapLocationSearchSheet extends StatefulWidget {
  final Function() getUserLocation;

  const MapLocationSearchSheet({Key? key, required this.getUserLocation})
      : super(key: key);

  @override
  State<MapLocationSearchSheet> createState() => _MapLocationSearchSheetState();
}

class _MapLocationSearchSheetState extends State<MapLocationSearchSheet> {
  TextEditingController searchController = TextEditingController();
  List<AutocompletePrediction> placePredictions = [];

  String? _inputText;

  void placeAutocomplate(String query) async {
    Uri uri =
        Uri.https("maps.googleapis.com", 'maps/api/place/autocomplete/json', {
      "input": query,
      "key": 'AIzaSyBCazeWB1DmiNcGqUmrzQ4sOdh47auHye0',
      "language": 'th',
    });
    String? response = await NetworkUtility.fetchUrl(uri);

    if (response != null) {
      PlaceAutocompleteResponse result =
          PlaceAutocompleteResponse.parseAutocompletResult(response);
      if (result.predictions != null) {
        setState(() {
          placePredictions = result.predictions!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  "ค้นหา",
                  style: AppTextStyle.sarabun1(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5.0,
                    spreadRadius: 0.0,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: TextFormField(
                controller: searchController,
                onChanged: (value) {
                  placeAutocomplate(value);
                  setState(() {
                    _inputText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "ค้นหาสถานที่",
                  hintStyle: AppTextStyle.sarabun2(context),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 30,
                    color: ColorGradient.getGradient().colors.first,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () {
                      searchController.clear();
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                ),
                style: AppTextStyle.sarabun2_1(context),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton.icon(
              //----------------test----------------
              onPressed: () async {
                widget.getUserLocation(); // เพิ่มวงเล็บ () เพื่อเรียกใช้เมธอด
                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                double latitude = position.latitude;
                double longitude = position.longitude;
                String message = "latitude: $latitude, longitude: $longitude";
                Fluttertoast.showToast(
                  msg: message,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.grey.shade200,
                  textColor: Colors.black,
                  fontSize: 16.0,
                );
              },

              //----------------test----------------
              icon: Icon(
                Icons.near_me_rounded,
                size: 20,
                //color: ColorGradient.getGradient().colors.first,
                color: Colors.grey.shade800,
              ),
              label: Text(
                "ใช้ตำแหน่งปัจจุบัน",
                style: AppTextStyle.sarabun3(context),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                elevation: 0,
                fixedSize: const Size(double.infinity, 40),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: placePredictions.length,
              itemBuilder: (context, index) => LocationList(
                press: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) => MapRouteSheet(
                      locationName: placePredictions[index]
                              .structuredFormatting
                              ?.mainText ??
                          '',
                    ),
                  );
                },
                location_name:
                    placePredictions[index].structuredFormatting?.mainText ??
                        '',
                address: placePredictions[index]
                        .structuredFormatting
                        ?.secondaryText ??
                    '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
