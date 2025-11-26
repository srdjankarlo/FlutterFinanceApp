import 'package:flutter/material.dart';

class OutlinedText extends StatelessWidget {
  final String text;
  final double size;
  final Color outlineColor;
  final Color fillColor;
  final double strokeWidth;

  const OutlinedText({
    super.key,
    required this.text,
    this.size = 24,
    this.outlineColor = Colors.black,
    this.fillColor = Colors.white,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = outlineColor,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}
