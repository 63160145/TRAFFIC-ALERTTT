import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData iconData;
  final Color? backgroundColor;
  final Color? iconColor;
  final double elevation;
  final double shapeRadius;
  final String? heroTag; // เพิ่มพารามิเตอร์ heroTag

  const CustomFAB({
    Key? key,
    required this.onPressed,
    required this.iconData,
    this.backgroundColor,
    this.iconColor,
    this.elevation = 1.0,
    this.shapeRadius = 10.0,
    this.heroTag, // เพิ่มพารามิเตอร์ heroTag
  }) : super(key: key); // เพิ่ม super(key: key) เพื่อส่งค่า key ไปยังคลาสแม่

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? Colors.white.withOpacity(1),
        elevation: elevation,
        mini: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapeRadius),
        ),
        heroTag: heroTag,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color(0xFF52B8CF), Color(0xFFABE9CD)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          child: Icon(
            iconData,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
