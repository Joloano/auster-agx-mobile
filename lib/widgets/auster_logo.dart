import 'package:flutter/material.dart';

class AusterLogo extends StatelessWidget {
  const AusterLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/auster-logo-bicolor.png',
      width: width,
      height: height,
      fit: fit,
      semanticLabel: 'Auster Tecnologia',
    );
  }
}
