import 'package:flutter/material.dart';
import 'package:traffic_base/map_models/map_models.dart';
import 'package:traffic_base/styles/colors_theme.dart';
import 'package:traffic_base/styles/text_style.dart';

class MapPolylineCancelSheet extends StatefulWidget {
  const MapPolylineCancelSheet({super.key});

  @override
  State<MapPolylineCancelSheet> createState() => _MapPolylineCancelSheetState();
}

class _MapPolylineCancelSheetState extends State<MapPolylineCancelSheet> {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10, left: 30),
                child: Text(
                  'จุดหมาย',
                  style: AppTextStyle.sarabun6(context),
                ),
              )
            ],
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 0, left: 20),
                    child: Icon(Icons.place_rounded),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'LocationName',
                    style: AppTextStyle.sarabun2_1(context),
                  ),
                ],
              ), /*Padding(
                padding: EdgeInsets.only(top: 10, left: 20),
                child: Text(
                  'LocationName',
                  style: AppTextStyle.sarabun2_1(context),
                ),
              ),*/
            ),
          ),
          SizedBox(height: 10),
          /*Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),*/
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              height: 50, // กำหนดความสูงของปุ่ม
              width: MediaQuery.of(context).size.width,
              child: FloatingActionButton(
                onPressed: () {
                  Future.delayed(
                    Duration(milliseconds: 150),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(),
                        ),
                      );
                    },
                  );
                },
                elevation: 0,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  'สิ้นสุดการเดินทาง',
                  style: AppTextStyle.sarabunCancel(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
