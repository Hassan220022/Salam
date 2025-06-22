import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../services/accessibility_service.dart';
import '../providers/enhanced_theme_provider.dart';
import '../../core/utils/app_theme.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> with TickerProviderStateMixin {
  final AccessibilityService _accessibilityService = AccessibilityService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _accessibilityService.initialize();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: _buildAppBar(context, themeProvider),
          body: AnimationLimiter(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              children: AnimationConfiguration.toStaggeredList(
                duration: themeProvider.animationDuration,
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildQuickAccessCard(context, themeProvider),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildTextToSpeechSection(context, themeProvider),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildThemeCustomizationSection(context, themeProvider),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildAccessibilityOptionsSection(context, themeProvider),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildFontCustomizationSection(context, themeProvider),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildTestSection(context, themeProvider),
                  const SizedBox(height: AppTheme.spacingXXL),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return AppBar(
      title: Semantics(
        label: 'Accessibility Settings Screen',
        child: const Text('Accessibility Settings'),
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.currentGradient,
        ),
      ),
      actions: [
        Semantics(
          label: 'Reset all accessibility settings to default values',
          child: IconButton(
            onPressed: () => _showResetDialog(context, themeProvider),
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility_new,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            _buildQuickActionButtons(context, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return Wrap(
      spacing: AppTheme.spacingM,
      runSpacing: AppTheme.spacingM,
      children: [
        _buildQuickActionButton(
          context,
          'Accessibility Mode',
          Icons.accessibility,
          !themeProvider.isHighContrast,
          () async {
            if (themeProvider.isHighContrast) {
              await themeProvider.disableAccessibilityMode();
              _accessibilityService
                  .announceAction('Accessibility mode disabled');
            } else {
              await themeProvider.enableAccessibilityMode();
              _accessibilityService
                  .announceAction('Accessibility mode enabled');
            }
          },
        ),
        _buildQuickActionButton(
          context,
          'High Contrast',
          Icons.contrast,
          themeProvider.isHighContrast,
          () async {
            await themeProvider.setHighContrast(!themeProvider.isHighContrast);
            _accessibilityService.announceAction(themeProvider.isHighContrast
                ? 'High contrast enabled'
                : 'High contrast disabled');
          },
        ),
        _buildQuickActionButton(
          context,
          'Large Text',
          Icons.format_size,
          themeProvider.fontScale > 1.0,
          () async {
            final newScale = themeProvider.fontScale > 1.0 ? 1.0 : 1.3;
            await themeProvider.setFontScale(newScale);
            _accessibilityService.announceAction(
                newScale > 1.0 ? 'Large text enabled' : 'Large text disabled');
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isEnabled,
    VoidCallback onPressed,
  ) {
    return Semantics(
      button: true,
      enabled: true,
      label:
          '$label ${isEnabled ? 'enabled' : 'disabled'}. Double tap to toggle.',
      child: Material(
        color: isEnabled
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                  size: 32,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                        fontWeight:
                            isEnabled ? FontWeight.bold : FontWeight.normal,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextToSpeechSection(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return _buildSection(
      context,
      'Text-to-Speech',
      Icons.record_voice_over,
      [
        _buildTtsToggle(context),
        _buildTtsSpeedSlider(context),
        _buildTtsPitchSlider(context),
        _buildTtsVolumeSlider(context),
        _buildTtsLanguageSelector(context),
        _buildTtsOptionsToggles(context),
      ],
    );
  }

  Widget _buildThemeCustomizationSection(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return _buildSection(
      context,
      'Theme Customization',
      Icons.palette,
      [
        _buildThemeModeSelector(context, themeProvider),
        _buildThemeStyleSelector(context, themeProvider),
        _buildThemeToggles(context, themeProvider),
        _buildThemePresets(context, themeProvider),
      ],
    );
  }

  Widget _buildAccessibilityOptionsSection(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return _buildSection(
      context,
      'Accessibility Options',
      Icons.accessibility_new,
      [
        _buildAccessibilityToggles(context, themeProvider),
        _buildAnimationControls(context, themeProvider),
        _buildHapticControls(context, themeProvider),
      ],
    );
  }

  Widget _buildFontCustomizationSection(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return _buildSection(
      context,
      'Font Customization',
      Icons.font_download,
      [
        _buildFontScaleSlider(context, themeProvider),
        _buildArabicFontSelector(context, themeProvider),
      ],
    );
  }

  Widget _buildTestSection(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return _buildSection(
      context,
      'Test Features',
      Icons.play_circle,
      [
        _buildTestButtons(context),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon,
      List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            ...children.map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: child,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsToggle(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _accessibilityService.speakingStream,
      builder: (context, snapshot) {
        return SwitchListTile(
          title: const Text('Enable Text-to-Speech'),
          subtitle: Text(_accessibilityService.isTtsEnabled
              ? 'Voice announcements enabled'
              : 'Voice announcements disabled'),
          value: _accessibilityService.isTtsEnabled,
          onChanged: (value) {
            _accessibilityService.setTtsEnabled(value);
            setState(() {});
          },
          secondary: Icon(
            _accessibilityService.isTtsEnabled
                ? Icons.volume_up
                : Icons.volume_off,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildTtsSpeedSlider(BuildContext context) {
    return ListTile(
      title: const Text('Speech Speed'),
      subtitle: Text(_accessibilityService.ttsSpeed.displayName),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: _accessibilityService.ttsSpeed.index.toDouble(),
          min: 0,
          max: TtsSpeed.values.length - 1,
          divisions: TtsSpeed.values.length - 1,
          onChanged: (value) {
            _accessibilityService.setTtsSpeed(TtsSpeed.values[value.round()]);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildTtsPitchSlider(BuildContext context) {
    return ListTile(
      title: const Text('Voice Pitch'),
      subtitle: Text('${(_accessibilityService.ttsPitch * 100).round()}%'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: _accessibilityService.ttsPitch,
          min: 0.5,
          max: 2.0,
          onChanged: (value) {
            _accessibilityService.setTtsPitch(value);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildTtsVolumeSlider(BuildContext context) {
    return ListTile(
      title: const Text('Voice Volume'),
      subtitle: Text('${(_accessibilityService.ttsVolume * 100).round()}%'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: _accessibilityService.ttsVolume,
          min: 0.0,
          max: 1.0,
          onChanged: (value) {
            _accessibilityService.setTtsVolume(value);
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildTtsLanguageSelector(BuildContext context) {
    return ListTile(
      title: const Text('Voice Language'),
      subtitle: Text(_accessibilityService.ttsLanguage.displayName),
      trailing: DropdownButton<TtsLanguage>(
        value: _accessibilityService.ttsLanguage,
        onChanged: (value) {
          if (value != null) {
            _accessibilityService.setTtsLanguage(value);
            setState(() {});
          }
        },
        items: TtsLanguage.values.map((language) {
          return DropdownMenuItem(
            value: language,
            child: Text(language.displayName),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTtsOptionsToggles(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Auto-read Content'),
          subtitle: const Text('Automatically read new content'),
          value: _accessibilityService.autoRead,
          onChanged: (value) {
            _accessibilityService.setAutoRead(value);
            setState(() {});
          },
        ),
        SwitchListTile(
          title: const Text('Announce Navigation'),
          subtitle: const Text('Announce screen changes'),
          value: _accessibilityService.announceNavigation,
          onChanged: (value) {
            _accessibilityService.setAnnounceNavigation(value);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildThemeModeSelector(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return ListTile(
      title: const Text('Theme Mode'),
      subtitle: Text(themeProvider.themeMode.name.toUpperCase()),
      trailing: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            label: Text('Light'),
            icon: Icon(Icons.light_mode),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text('Dark'),
            icon: Icon(Icons.dark_mode),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            label: Text('Auto'),
            icon: Icon(Icons.auto_mode),
          ),
        ],
        selected: {themeProvider.themeMode},
        onSelectionChanged: (Set<ThemeMode> selection) {
          themeProvider.setThemeMode(selection.first);
        },
      ),
    );
  }

  Widget _buildThemeStyleSelector(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return ListTile(
      title: const Text('Color Theme'),
      subtitle: Text(themeProvider.themeStyle.name),
      trailing: DropdownButton<AppThemeStyle>(
        value: themeProvider.themeStyle,
        onChanged: (value) {
          if (value != null) {
            themeProvider.setThemeStyle(value);
          }
        },
        items: AppThemeStyle.values.map((style) {
          return DropdownMenuItem(
            value: style,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: style.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(style.name),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeToggles(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('High Contrast Mode'),
          subtitle: const Text('Increase contrast for better visibility'),
          value: themeProvider.isHighContrast,
          onChanged: themeProvider.setHighContrast,
        ),
        SwitchListTile(
          title: const Text('Dynamic Colors'),
          subtitle: const Text('Use system colors when available'),
          value: themeProvider.autoTheme,
          onChanged: themeProvider.setAutoTheme,
        ),
      ],
    );
  }

  Widget _buildThemePresets(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: themeProvider.applyIslamicPreset,
            icon: const Icon(Icons.mosque, size: 16),
            label: const Text('Islamic', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: themeProvider.applyModernPreset,
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Modern', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: themeProvider.applyElegantPreset,
            icon: const Icon(Icons.diamond, size: 16),
            label: const Text('Elegant', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityToggles(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Reduce Animations'),
          subtitle: const Text('Minimize motion for sensitive users'),
          value: themeProvider.reduceAnimations,
          onChanged: themeProvider.setReduceAnimations,
        ),
        SwitchListTile(
          title: const Text('Enable Haptic Feedback'),
          subtitle: const Text('Vibration feedback for interactions'),
          value: themeProvider.enableHaptics,
          onChanged: themeProvider.setEnableHaptics,
        ),
      ],
    );
  }

  Widget _buildAnimationControls(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return ListTile(
      title: const Text('Animation Speed'),
      subtitle: Text(themeProvider.reduceAnimations ? 'Fast' : 'Normal'),
      trailing: Switch(
        value: !themeProvider.reduceAnimations,
        onChanged: (value) => themeProvider.setReduceAnimations(!value),
      ),
    );
  }

  Widget _buildHapticControls(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return ListTile(
      title: const Text('Haptic Intensity'),
      subtitle: const Text('Touch feedback strength'),
      trailing: IconButton(
        onPressed: themeProvider.enableHaptics
            ? () {
                // Simple haptic test
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Haptic feedback tested')),
                );
              }
            : null,
        icon: const Icon(Icons.vibration),
      ),
    );
  }

  Widget _buildFontScaleSlider(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return ListTile(
      title: const Text('Text Size'),
      subtitle: Text('${(themeProvider.fontScale * 100).round()}%'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: themeProvider.fontScale,
          min: 0.7,
          max: 2.0,
          divisions: 13,
          onChanged: themeProvider.setFontScale,
        ),
      ),
    );
  }

  Widget _buildArabicFontSelector(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    return ListTile(
      title: const Text('Arabic Font'),
      subtitle: Text(themeProvider.arabicFont.displayName),
      trailing: DropdownButton<ArabicFontFamily>(
        value: themeProvider.arabicFont,
        onChanged: (value) {
          if (value != null) {
            themeProvider.setArabicFont(value);
          }
        },
        items: ArabicFontFamily.values.map((font) {
          return DropdownMenuItem(
            value: font,
            child: Text(font.displayName),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _accessibilityService.testTts,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Test TTS'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _accessibilityService.testArabicTts,
            icon: const Icon(Icons.language),
            label: const Text('Test Arabic'),
          ),
        ),
      ],
    );
  }

  void _showResetDialog(
      BuildContext context, EnhancedThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'This will reset all accessibility and theme settings to their default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await themeProvider.resetToDefaults();
              Navigator.of(context).pop();
              _accessibilityService
                  .announceSuccess('Settings reset to defaults');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// Simple haptic test screen
class HapticTestScreen extends StatelessWidget {
  const HapticTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haptic Test'),
      ),
      body: const Center(
        child: Text('Haptic Test Screen\n(Implementation coming soon)'),
      ),
    );
  }
}
