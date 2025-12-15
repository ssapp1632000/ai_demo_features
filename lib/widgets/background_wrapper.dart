import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;

    if (!isDarkMode) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: child,
      );
    }

    return Stack(
      children: [
        Transform.scale(
          scale: 1.3,
          alignment: Alignment.topLeft,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Dark.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
