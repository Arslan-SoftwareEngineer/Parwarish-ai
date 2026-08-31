import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class AdaptiveTileWidget extends StatelessWidget {
  final String titleEn;
  final String titleUr;
  final String descriptionEn;
  final String descriptionUr;
  final IconData icon;
  final LinearGradient gradient;
  final String interactionType; // 'voice', 'camera', 'breathe'
  final VoidCallback onTap;

  const AdaptiveTileWidget({
    super.key,
    required this.titleEn,
    required this.titleUr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.icon,
    required this.gradient,
    required this.interactionType,
    required this.onTap,
  });

  IconData _getInteractionIcon() {
    switch (interactionType) {
      case 'camera':
        return Icons.videocam_rounded;
      case 'breathe':
        return Icons.air_rounded;
      default:
        return Icons.mic_rounded;
    }
  }

  String _getInteractionLabel(bool isUrdu) {
    if (isUrdu) {
      switch (interactionType) {
        case 'camera':
          return 'کیمرہ';
        case 'breathe':
          return 'سانس';
        default:
          return 'آواز';
      }
    } else {
      switch (interactionType) {
        case 'camera':
          return 'Camera';
        case 'breathe':
          return 'Breathe';
        default:
          return 'Voice';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;
    final title = isUrdu ? titleUr : titleEn;
    final desc = isUrdu ? descriptionUr : descriptionEn;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.heavyShadow(gradient.colors.first, opacity: 0.32, blur: 16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Icon(icon, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),

                // Title and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          // Interaction Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getInteractionIcon(), color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _getInteractionLabel(isUrdu),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Arrow Button
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Icon(
                    isUrdu ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                    color: gradient.colors.first,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }
}
