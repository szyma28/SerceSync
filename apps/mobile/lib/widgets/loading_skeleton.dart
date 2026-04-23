import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.radius = 14,
    this.color,
  });

  final double height;
  final double? width;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? AppTheme.primaryBlueLight.withAlpha(120),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(215),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: child,
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  const SkeletonAvatar({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBlock(height: size, width: size, radius: size / 2);
  }
}
