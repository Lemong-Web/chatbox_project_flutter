import 'package:flutter/material.dart';

class Line extends StatelessWidget {
  const Line({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
         decoration: BoxDecoration(
          // ignore: deprecated_member_use
          border: Border.all(color: Colors.black.withOpacity(0.3))
         ),
         width: 260,
         height: 0,
      ),
    );
  }
}