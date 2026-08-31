import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class BreatheCircleWidget extends StatefulWidget {
  final double soundLevel;
  final VoidCallback? onCycleCompleted;

  const BreatheCircleWidget({
    super.key,
    this.soundLevel = 0.0,
    this.onCycleCompleted,
  });

  @override
  State<BreatheCircleWidget> createState() => _BreatheCircleWidgetState();
}

class _BreatheCircleWidgetState extends State<BreatheCircleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _scaleAnimation;
  String _breathePromptEn = 'Breathe In...';
  String _breathePromptUr = 'سانس اندر لیں...';

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.25).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOutSine),
    );

    _breatheController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() {
          _breathePromptEn = 'Breathe In...';
          _breathePromptUr = 'سانس اندر لیں...';
        });
      } else if (status == AnimationStatus.reverse) {
        setState(() {
          _breathePromptEn = 'Breathe Out...';
          _breathePromptUr = 'سانس باہر نکالیں...';
        });
        widget.onCycleCompleted?.call();
      }
    });

    _breatheController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;
    final prompt = isUrdu ? _breathePromptUr : _breathePromptEn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _breatheController,
          builder: (context, child) {
            final scale = _scaleAnimation.value + (widget.soundLevel * 0.15);
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ripple Ring
                Transform.scale(
                  scale: scale * 1.2,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.electricCyan.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                // Middle Pulsing Ring
                Transform.scale(
                  scale: scale * 1.1,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.electricBlue.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Center Glowing Core
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.blueCyanGradient,
                      boxShadow: AppTheme.heavyShadow(AppTheme.electricBlue, opacity: 0.5, blur: 24),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.air_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Text(
            prompt,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
