import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../services/localization_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../welcome_screen.dart';
import '../child/child_profile_selection.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  String? _selectedDeviceSpace;

  @override
  void initState() {
    super.initState();
    _loadDeviceSpace();
  }

  Future<void> _loadDeviceSpace() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDeviceSpace = prefs.getString('selected_device_space') ?? 'parent';
    });
  }

  Future<void> _switchDeviceSpace(String newSpace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_device_space', newSpace);
    await AuthService.instance.setDefaultDeviceMode(newSpace);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device space set to ${newSpace.toUpperCase()}')),
      );
      if (newSpace == 'child') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ChildProfileSelection(parentUid: AuthService.instance.currentUserUid),
          ),
          (route) => false,
        );
      } else {
        setState(() => _selectedDeviceSpace = newSpace);
      }
    }
  }

  Future<void> _resetFirstTimeSetup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Space Preference?'),
        content: const Text(
          'This will clear the 1-time space selection lock and allow you to view the Welcome Screen and guidelines on next launch.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_device_space');
      await AuthService.instance.setDefaultDeviceMode(null);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
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
              isUrdu ? 'والدین کی سیٹنگز' : 'Parent Settings & Control',
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
                // 1. Account & Security summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shield_rounded, color: primaryColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AuthService.instance.currentUserEmail,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Verified Parent Account • Device Space: ${_selectedDeviceSpace?.toUpperCase() ?? "PARENT"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Display Theme Mode (Dark / Light / System Aligned)
                _buildSectionHeader(
                  icon: Icons.brightness_medium_rounded,
                  title: isUrdu ? 'ڈسپلے موڈ (Dark/Light/System)' : 'Display Mode (Dark / Light / System Aligned)',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        title: isUrdu ? 'روشن' : 'Light',
                        icon: Icons.light_mode_rounded,
                        mode: ThemeMode.light,
                        isSelected: currentMode == ThemeMode.light,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeCard(
                        title: isUrdu ? 'تاریک' : 'Dark',
                        icon: Icons.dark_mode_rounded,
                        mode: ThemeMode.dark,
                        isSelected: currentMode == ThemeMode.dark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeCard(
                        title: isUrdu ? 'خودکار' : 'System',
                        icon: Icons.brightness_auto_rounded,
                        mode: ThemeMode.system,
                        isSelected: currentMode == ThemeMode.system,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. Color Scheme
                _buildSectionHeader(
                  icon: Icons.palette_rounded,
                  title: isUrdu ? 'ایپ کا رنگ' : 'Color Scheme',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildColorCard(AppColorScheme.orange, 'Orange', AppTheme.primaryOrange, currentScheme == AppColorScheme.orange),
                    _buildColorCard(AppColorScheme.blue, 'Blue', const Color(0xFF3B82F6), currentScheme == AppColorScheme.blue),
                    _buildColorCard(AppColorScheme.green, 'Mint', const Color(0xFF10B981), currentScheme == AppColorScheme.green),
                    _buildColorCard(AppColorScheme.purple, 'Lavender', const Color(0xFF8B5CF6), currentScheme == AppColorScheme.purple),
                    _buildColorCard(AppColorScheme.pink, 'Pink', const Color(0xFFEC4899), currentScheme == AppColorScheme.pink),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Font Size Scaling
                _buildSectionHeader(
                  icon: Icons.format_size_rounded,
                  title: isUrdu ? 'فونٹ اسکیلنگ' : 'Font Size Scaling',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildFontOptionCard('Normal (1.0x)', 1.0, (currentScale - 1.0).abs() < 0.05),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFontOptionCard('Large (1.15x)', 1.15, (currentScale - 1.15).abs() < 0.05),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFontOptionCard('X-Large (1.3x)', 1.3, (currentScale - 1.3).abs() < 0.05),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Language Selection
                _buildSectionHeader(
                  icon: Icons.language_rounded,
                  title: isUrdu ? 'زبان' : 'App Language',
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: Theme.of(context).cardColor,
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(isUrdu ? 'اردو' : 'English'),
                  subtitle: Text(isUrdu ? 'زبان تبدیل کریں' : 'Switch between English and Urdu'),
                  trailing: Switch(
                    value: isUrdu,
                    onChanged: (val) {
                      LocalizationService.instance.toggleLanguage();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Device Space Lock & Management
                _buildSectionHeader(
                  icon: Icons.phonelink_setup_rounded,
                  title: isUrdu ? 'ڈیوائس اسپیس مینجمنٹ' : 'Device Space Management',
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This device is currently configured for:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDeviceSpace == 'child' ? '🚀 Child Space (Child Device)' : '🛡️ Parent Portal (Parent Device)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _switchDeviceSpace('child'),
                              icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                              label: const Text('Switch to Child Space'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetFirstTimeSetup,
                              icon: const Icon(Icons.restart_alt_rounded, size: 16),
                              label: const Text('Reset Setup'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Security Alerts & Parent Notifications
                _buildSectionHeader(
                  icon: Icons.notifications_active_rounded,
                  title: isUrdu ? 'سیکیورٹی الرٹس اور لاگز' : 'Child Security Alerts & History',
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<List<ParentNotification>>(
                  valueListenable: ParentNotificationService.instance.notificationsNotifier,
                  builder: (context, notifs, _) {
                    if (notifs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No security alerts or settings change attempts.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        ...notifs.take(5).map((n) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: n.type == 'settings_access_attempt'
                                    ? Colors.amber.withOpacity(0.4)
                                    : Colors.grey.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  n.type == 'settings_access_attempt'
                                      ? Icons.warning_amber_rounded
                                      : Icons.notifications_rounded,
                                  color: n.type == 'settings_access_attempt'
                                      ? Colors.amber.shade700
                                      : primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.title,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        n.message,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton(
                          onPressed: () {
                            ParentNotificationService.instance.clearAll();
                            setState(() {});
                          },
                          child: const Text('Clear All Alerts'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildModeCard({
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
            Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 26),
            const SizedBox(height: 6),
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

  Widget _buildColorCard(AppColorScheme scheme, String name, Color color, bool isSelected) {
    return InkWell(
      onTap: () {
        ThemeService.instance.setColorScheme(scheme);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontOptionCard(String title, double scale, bool isSelected) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        ThemeService.instance.setFontScale(scale);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? primaryColor : null,
            ),
          ),
        ),
      ),
    );
  }
}
