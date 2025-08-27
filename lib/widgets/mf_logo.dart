import 'package:flutter/material.dart';

class MFLogo extends StatelessWidget {
  final double height;
  const MFLogo({super.key, this.height = 80});
  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo.png', height: height, fit: BoxFit.contain);
  }
}
