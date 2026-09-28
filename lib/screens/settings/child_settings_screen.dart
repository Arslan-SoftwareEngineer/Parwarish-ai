import 'package:flutter/material.dart';
import '../../services/theme_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';

class ChildSettingsScreen extends StatefulWidget {
  const ChildSettingsScreen({super.key});

  @override
  State<ChildSettingsScreen> createState() => _ChildSettingsScreenState();
}

class _ChildSettingsScreenState extends State<ChildSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentScheme = ThemeService.instance.currentColorScheme;
    final currentMode = ThemeService.instance.currentThemeMode;
    final currentScale = ThemeService.instance.currentFontScale;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, locale, _) {
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isUrdu ? 'سیٹنگز اور ترجیحات' : 'Child Space Settings',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Parent authorization badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isUrdu
                            ? 'والدین کی توثیق ہوچکی ہے۔ ترجیحات تبدیل کی جا سکتی ہیں۔'
                            : 'Parent Verified: Safe personalization options for child.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Theme Mode (Dark / Light / System Aligned)
                _buildSectionHeader(
                  icon: Icons.brightness_medium_rounded,
                  title: isUrdu ? 'ڈسپلے موڈ' : 'Theme Mode (Light / Dark / System)',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeOptionCard(
                        title: isUrdu ? 'روشن' : 'Light',
                        icon: Icons.light_mode_rounded,
                        mode: ThemeMode.light,
                        isSelected: currentMode == ThemeMode.light,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeOptionCard(
                        title: isUrdu ? 'تاریک' : 'Dark',
                        icon: Icons.dark_mode_rounded,
                        mode: ThemeMode.dark,
                        isSelected: currentMode == ThemeMode.dark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeOptionCard(
                        title: isUrdu ? 'خودکار' : 'System',
                        icon: Icons.brightness_auto_rounded,
                        mode: ThemeMode.system,
                        isSelected: currentMode == ThemeMode.system,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Color Scheme Changing
                _buildSectionHeader(
                  icon: Icons.palette_rounded,
                  title: isUrdu ? 'پسندیدہ رنگ' : 'Favorite Color Scheme',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildColorCard(
                      scheme: AppColorScheme.orange,
                      name: isUrdu ? 'نارنجی' : 'Sunny Orange',
                      color: AppTheme.primaryOrange,
                      isSelected: currentScheme == AppColorScheme.orange,
                    ),
                    _buildColorCard(
                      scheme: AppColorScheme.blue,
                      name: isUrdu ? 'نیلا' : 'Ocean Blue',
                      color: const Color(0xFF3B82F6),
                      isSelected: currentScheme == AppColorScheme.blue,
                    ),
                    _buildColorCard(
                      scheme: AppColorScheme.green,
                      name: isUrdu ? 'سبز' : 'Calm Mint',
                      color: const Color(0xFF10B981),
                      isSelected: currentScheme == AppColorScheme.green,
                    ),
                    _buildColorCard(
                      scheme: AppColorScheme.purple,
                      name: isUrdu ? 'جامنی' : 'Lavender',
                      color: const Color(0xFF8B5CF6),
                      isSelected: currentScheme == AppColorScheme.purple,
                    ),
                    _buildColorCard(
                      scheme: AppColorScheme.pink,
                      name: isUrdu ? 'گلابی' : 'Sunset Pink',
                      color: const Color(0xFFEC4899),
                      isSelected: currentScheme == AppColorScheme.pink,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Font Size Scaling
                _buildSectionHeader(
                  icon: Icons.format_size_rounded,
                  title: isUrdu ? 'فونٹ سائز' : 'Font Size Scaling',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildFontOptionCard(
                        title: isUrdu ? 'عام' : 'Normal',
                        scaleLabel: '1.0x',
                        scale: 1.0,
                        isSelected: (currentScale - 1.0).abs() < 0.05,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFontOptionCard(
                        title: isUrdu ? 'بڑا' : 'Large',
                        scaleLabel: '1.15x',
                        scale: 1.15,
                        isSelected: (currentScale - 1.15).abs() < 0.05,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFontOptionCard(
                        title: isUrdu ? 'بہت بڑا' : 'Extra Large',
                        scaleLabel: '1.3x',
                        scale: 1.3,
                        isSelected: (currentScale - 1.3).abs() < 0.05,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Done Button
                ElevatedButton(
                  key: const Key('save_child_settings_btn'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isUrdu ? 'محفوظ کریں' : 'Save & Close'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildModeOptionCard({
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        ThemeService.instance.setThemeMode(mode);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard({
    required AppColorScheme scheme,
    required String name,
    required Color color,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ThemeService.instance.setColorScheme(scheme);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontOptionCard({
    required String title,
    required String scaleLabel,
    required double scale,
    required bool isSelected,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        ThemeService.instance.setFontScale(scale);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              scaleLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
