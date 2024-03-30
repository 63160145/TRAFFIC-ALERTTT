import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyle {
//TextTrafficAlret
  static TextStyle roboto(BuildContext context) {
    return GoogleFonts.roboto(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
      shadows: [
        Shadow(
          color: Colors.grey.withOpacity(0.3), // สีของเงา
          offset: Offset(2, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

//TextSearch
  static TextStyle sarabun1(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade900,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }

//TextFillSearch
  static TextStyle sarabun2(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade500,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }

  //TextFillSearch2
  static TextStyle sarabun2_1(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade900,
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }

//GetUser
  static TextStyle sarabun3(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade900,
      fontSize: 16.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }

//Location1
  static TextStyle sarabun4(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade900,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }

//Location2
  static TextStyle sarabun5(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade500,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }

  //Time
  static TextStyle sarabun6(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade900,
      fontSize: 16.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    );
  }

  static TextStyle roboto7(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade900,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }

  static TextStyle sarabunPolyline(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade900,
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      decoration: TextDecoration.none,
    );
  }

  static TextStyle sarabunPolylineTime(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.grey.shade700,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      decoration: TextDecoration.none,
    );
  }

  //TextFillSearch2
  static TextStyle sarabunCancel(BuildContext context) {
    return GoogleFonts.sarabun(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );
  }
}
