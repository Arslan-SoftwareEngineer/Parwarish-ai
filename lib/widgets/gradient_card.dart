import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool enableBounce;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient = AppTheme.orangePinkGradient,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.onTap,
    this.width,
    this.height,
    this.enableBounce = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppTheme.heavyShadow(gradient.colors.first),
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: card,
        ),
      );
    }

    if (enableBounce) {
      return card
          .animate(onPlay: (controller) => controller.forward())
          .scale(duration: 350.ms, curve: Curves.easeOutBack, begin: const Offset(0.95, 0.95), end: const Offset(1, 1))
          .fadeIn(duration: 300.ms);
    }

    return card;
  }
}
