import 'package:flutter/material.dart';
import 'package:traffic_base/styles/text_style.dart';

import '../polyline/map_route_start.dart';

class LocationList extends StatelessWidget {
  const LocationList(
      {Key? key,
      required this.location_name,
      required this.address,
      required this.press})
      : super(key: key);

  final String location_name;
  final String address;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 18),
            child: ListTile(
              onTap: //press,
                  () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return MapRouteSheet(locationName: location_name);
                  },
                );
              },
              leading: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.place_sharp,
                  size: 25,
                  color: Colors.grey.shade800,
                ),
              ),
              /*Icon(
                Icons.place_sharp,
                size: 30,
                color: Colors.black,
              ),*/
              title: Text(
                location_name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.sarabun4(context),
              ),
              subtitle: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.sarabun5(context),
              ),
              trailing: Icon(
                Icons.arrow_outward_rounded,
                size: 25,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Divider(
                    height: 0.5,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
