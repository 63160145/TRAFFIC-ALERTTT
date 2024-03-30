import 'package:google_maps_flutter/google_maps_flutter.dart';

class Direction {
  final String description;
  final String distance;
  final String duration;
  final LatLng startPoint;
  final LatLng endPoint;
  final String maneuver; // Define the 'maneuver' property here

  Direction({
    required this.description,
    required this.distance,
    required this.duration,
    required this.startPoint,
    required this.endPoint,
    required this.maneuver, // Include 'maneuver' in the constructor parameters
  });

  factory Direction.fromJson(Map<String, dynamic> json) {
    final startLocation = json['start_location'];
    final endLocation = json['end_location'];

    // ใช้ ?? เพื่อกำหนดค่าเริ่มต้นเมื่อค่าที่ได้เป็น null
    return Direction(
      description: json['html_instructions'] ?? 'ไม่มีคำอธิบาย',
      distance: json['distance']?['text'] ?? 'ไม่มีข้อมูลระยะทาง',
      duration: json['duration']?['text'] ?? 'ไม่มีข้อมูลระยะเวลา',
      startPoint:
          LatLng(startLocation?['lat'] ?? 0.0, startLocation?['lng'] ?? 0.0),
      endPoint: LatLng(endLocation?['lat'] ?? 0.0, endLocation?['lng'] ?? 0.0),
      maneuver: json['maneuver'] ?? '',
    );
  }
}
