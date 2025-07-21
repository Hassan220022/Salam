import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../domain/entities/surah_entity.dart';
import '../providers/preference_settings_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/surah_provider.dart';
import '../providers/enhanced_theme_provider.dart';

import '../../data/models/translation.dart';
import '../../data/models/tafsir.dart';
import '../../services/audio_player_service.dart';
import '../../services/quran_service.dart';
import 'package:flutter/gestures.dart';
import 'package:visibility_detector/visibility_detector.dart';

class SurahReaderScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? highlightAyah; // Optional parameter for highlighting
  const SurahReaderScreen({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    this.highlightAyah,
  }) : super(key: key);
  @override
  _SurahReaderScreenState createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  List<Verse> _ayahs = [];
  TranslationSet? _translations;
  TafsirSet? _tafsir;
  bool _isLoading = true;
  bool _isError = false;
  static const String basmallahImagePath = 'assets/basmallah.png';
  late AudioPlayerService _audioPlayerService;
  late QuranService _quranService;
  int? _currentlyPlayingAyah;
  double? _originalBrightness;
  final ScrollController _scrollController = ScrollController();
  int _totalAyahs = 0;
  int _lastReportedAyah =
      0; // Track last reported ayah to avoid excessive updates

  @override
  void initState() {
    super.initState();
    _audioPlayerService = AudioPlayerService();
    _quranService = QuranService();
    _initializeBrightness();

    // Load surah data after the initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSurah();
      _loadTranslations();
      _loadTafsir();
    });

    // Remove scroll listener for progress tracking
    // _scrollController.addListener(_onScroll);
  }

  Future<void> _loadSurah() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final surahProvider = context.read<SurahProvider>();
      final success = await surahProvider.loadSurah(widget.surahNumber);

      if (!mounted) return;

      if (success) {
        final surah = surahProvider.getSurahByNumber(widget.surahNumber);

        if (surah != null && surah.verses.isNotEmpty) {
          final filteredVerses = surah.verses.where((verse) {
            final normalizedText = normalizeText(verse.arabicText);
            return !normalizedText.contains('بِسْمِ ٱللَّهِ');
          }).toList();

          setState(() {
            _ayahs = filteredVerses;
            _totalAyahs = surah.numberOfAyahs;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      } else {
        // Check if there's an error message from the provider
        final errorMessage = surahProvider.errorMessage;
        setState(() {
          _isError = true;
          _isLoading = false;
        });

        if (mounted && errorMessage != null) {
          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading surah ${widget.surahNumber}: $e');
      }

      if (!mounted) return;

      setState(() {
        _isError = true;
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to load surah. Please check your connection.');
    }
  }

  String normalizeText(String input) {
    final diacritics = RegExp(r'[\u064B-\u0652]');
    return input
        .replaceAll(diacritics, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _playAudio(int ayahNumber) async {
    String surahStr = widget.surahNumber.toString().padLeft(3, '0');
    String ayahStr = ayahNumber.toString().padLeft(3, '0');
    // Revert to original 64kbps stream for compatibility
    String audioUrl =
        'https://everyayah.com/data/AbdulSamad_64kbps_QuranExplorer.Com/$surahStr$ayahStr.mp3';

    try {
      await _audioPlayerService.play(audioUrl);
      setState(() {
        _currentlyPlayingAyah = ayahNumber;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error playing audio for ayah $ayahNumber: $e');
      }
      _showErrorSnackBar('Unable to play audio. Please try again.');
    }
  }

  void _stopAudio() async {
    try {
      await _audioPlayerService.stop();
      setState(() {
        _currentlyPlayingAyah = null;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error stopping audio: $e');
      }
      _showErrorSnackBar('Error stopping audio.');
    }
  }

  void _showBookmarkDialog(Verse verse) {
    final noteController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.bookmark_add,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Bookmark',
                          style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Save this verse for later',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Verse preview card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.surahName} ${verse.number}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse.arabicText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Quran',
                              fontSize: 18,
                              height: 1.8,
                            ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      if (verse.translation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          verse.translation!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Note input
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Add a personal note (optional)',
                  hintText: 'Why is this verse meaningful to you?',
                  prefixIcon: const Icon(Icons.note_add),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final success =
                            await context.read<BookmarksProvider>().addBookmark(
                                  surahNumber: widget.surahNumber,
                                  verseNumber: verse.number,
                                  note: noteController.text.trim().isEmpty
                                      ? null
                                      : noteController.text.trim(),
                                );

                        if (mounted) {
                          Navigator.pop(context);
                          _showSuccessSnackBar(
                            success
                                ? 'Bookmark saved successfully!'
                                : 'Failed to save bookmark',
                            isSuccess: success,
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.bookmark_add, size: 20),
                      label: const Text('Save Bookmark'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get current brightness: $e');
      }
      // Fallback to default brightness if unable to get current
      _originalBrightness = 0.5;
    }
  }

  // Remove _onScroll and any related logic

  Future<void> _loadTranslations() async {
    final prefProvider =
        Provider.of<PreferenceSettingsProvider>(context, listen: false);
    if (!prefProvider.showTranslation) return;

    try {
      final translations = await _quranService.getTranslations(
        widget.surahNumber,
        [prefProvider.selectedTranslation],
      );
      if (mounted) {
        setState(() {
          _translations = translations;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'Error loading translations for surah ${widget.surahNumber}: $e');
      }
      // Don't show error to user as translations are optional
      // The UI will gracefully handle missing translations
    }
  }

  Future<void> _loadTafsir() async {
    final prefProvider =
        Provider.of<PreferenceSettingsProvider>(context, listen: false);
    if (!prefProvider.showTafsir) {
      // Clear tafsir when disabled
      if (mounted) {
        setState(() {
          _tafsir = null;
        });
      }
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint(
            '📖 Loading tafsir for surah ${widget.surahNumber} with edition: ${prefProvider.selectedTafsir}');
      }

      final tafsir = await _quranService.getTafsir(
        widget.surahNumber,
        prefProvider.selectedTafsir,
      );

      if (mounted) {
        setState(() {
          _tafsir = tafsir;
        });

        if (kDebugMode) {
          debugPrint('✅ Tafsir loaded: ${tafsir.tafasir.length} entries');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ Error loading tafsir for surah ${widget.surahNumber}: $e');
      }

      // Set empty tafsir to show "not available" message
      if (mounted) {
        setState(() {
          _tafsir = TafsirSet(
            tafasir: [],
            surahName: widget.surahName,
            surahNumber: widget.surahNumber,
          );
        });
      }
    }
  }

  /// Helper method to show error messages to users
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Helper method to show success messages to users
  void _showSuccessSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBeautifulSelector({
    required String currentValue,
    required Map<String, String> options,
    required Function(String) onSelected,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Select Option',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),

                // Options List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final entry = options.entries.elementAt(index);
                      final isSelected = entry.value == currentValue;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected
                            ? color.withOpacity(0.1)
                            : theme.colorScheme.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? color.withOpacity(0.5)
                                : theme.dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            onSelected(entry.key);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? color : Colors.grey,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? color
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentValue,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayerService.dispose();
    // Restore original brightness if night reading mode was used
    if (_originalBrightness != null) {
      ScreenBrightness().setScreenBrightness(_originalBrightness!);
    }
    super.dispose();
  }

  Widget _buildReadingControls(PreferenceSettingsProvider prefProvider) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.tune, color: theme.colorScheme.onPrimary, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Reading Settings',
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Font Size Control
                  Consumer<EnhancedThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildSettingsCard(
                        icon: Icons.format_size,
                        title: 'Font Size',
                        subtitle: '${themeProvider.arabicFontSize.round()}px',
                        child: Slider(
                          value: themeProvider.arabicFontSize,
                          min: 14.0,
                          max: 32.0,
                          divisions: 18,
                          onChanged: (value) {
                            themeProvider.setArabicFontSize(value);
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Reading Mode Selection
                  _buildSettingsCard(
                    icon: Icons.nightlight_round,
                    title: 'Reading Mode',
                    subtitle: 'Choose your preferred reading experience',
                    child: Consumer<EnhancedThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Column(
                          children: [
                            RadioListTile<ReadingMode>(
                              title: const Text('Normal'),
                              subtitle: const Text('Regular reading mode'),
                              value: ReadingMode.normal,
                              groupValue: themeProvider.readingMode,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setReadingMode(value);
                                  if (_originalBrightness != null) {
                                    ScreenBrightness().setScreenBrightness(_originalBrightness!);
                                  }
                                }
                              },
                            ),
                            RadioListTile<ReadingMode>(
                              title: const Text('Night Reading'),
                              subtitle: const Text('Dark theme with dimmed screen'),
                              value: ReadingMode.night,
                              groupValue: themeProvider.readingMode,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setReadingMode(value);
                                  if (_originalBrightness != null) {
                                    ScreenBrightness().setScreenBrightness(0.3);
                                  }
                                }
                              },
                            ),
                            RadioListTile<ReadingMode>(
                              title: const Text('Comfort Reading'),
                              subtitle: const Text('Warm colors for extended reading'),
                              value: ReadingMode.comfort,
                              groupValue: themeProvider.readingMode,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setReadingMode(value);
                                  if (_originalBrightness != null) {
                                    ScreenBrightness().setScreenBrightness(_originalBrightness!);
                                  }
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Translation Section
                  _buildSettingsCard(
                    icon: Icons.translate,
                    title: 'Translation',
                    subtitle:
                        prefProvider.showTranslation ? 'Enabled' : 'Disabled',
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: prefProvider.showTranslation,
                          onChanged: (value) {
                            prefProvider.toggleTranslation(value);
                            if (value) _loadTranslations();
                          },
                          title: const Text('Show Translation'),
                        ),
                        if (prefProvider.showTranslation) ...[
                          const SizedBox(height: 12),
                          _buildBeautifulSelector(
                            currentValue: PreferenceSettingsProvider
                                        .availableTranslations[
                                    prefProvider.selectedTranslation] ??
                                'Select Translation',
                            options: PreferenceSettingsProvider
                                .availableTranslations,
                            onSelected: (key) {
                              prefProvider.setSelectedTranslation(key);
                              _loadTranslations();
                            },
                            icon: Icons.translate,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tafsir Section
                  _buildSettingsCard(
                    icon: Icons.menu_book,
                    title: 'Tafsir (Commentary)',
                    subtitle: prefProvider.showTafsir ? 'Enabled' : 'Disabled',
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: prefProvider.showTafsir,
                          onChanged: (value) {
                            prefProvider.toggleTafsir(value);
                            if (value) _loadTafsir();
                          },
                          title: const Text('Show Commentary'),
                        ),
                        if (prefProvider.showTafsir) ...[
                          const SizedBox(height: 12),
                          _buildBeautifulSelector(
                            currentValue:
                                PreferenceSettingsProvider.availableTafsir[
                                        prefProvider.selectedTafsir] ??
                                    'Select Tafsir',
                            options: PreferenceSettingsProvider.availableTafsir,
                            onSelected: (key) {
                              prefProvider.setSelectedTafsir(key);
                              _loadTafsir();
                            },
                            icon: Icons.menu_book,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.secondary;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildQuranPage(BuildContext context, PreferenceSettingsProvider prefProvider) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<EnhancedThemeProvider>(context);
    final isDark = themeProvider.isDarkTheme(context);
    // Helper to convert int to Arabic-Indic numerals
    String toArabicNumber(int number) {
      const arabicDigits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
      return number.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
    }
    // Themed color for ayah marker and surah name
    final ayahMarkerColor = isDark ? Colors.white : Colors.black;
    final surahNameColor = isDark ? Colors.white : Colors.black;
    final surahNameFontSize = themeProvider.arabicFontSize + 2; // Reduced for better fit
    // Build a single list of InlineSpans for the whole surah
    final List<InlineSpan> ayahSpans = [];
    for (final verse in _ayahs) {
      final isHighlighted = widget.highlightAyah != null && verse.number == widget.highlightAyah;
      ayahSpans.add(
        TextSpan(
          text: verse.arabicText.trim() + ' ',
          style: TextStyle(
            fontFamily: 'Kitab',
            fontSize: themeProvider.arabicFontSize + 2,
            color: isDark ? const Color(0xFFE8F4FD) : themeProvider.getReadingModeTextColor(context),
            backgroundColor: isHighlighted ? ayahMarkerColor.withOpacity(0.15) : null,
            height: 1.3,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildAyahActionMenu(context, verse, _currentlyPlayingAyah == verse.number),
              );
            },
        ),
      );
      ayahSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildAyahActionMenu(context, verse, _currentlyPlayingAyah == verse.number),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
                border: Border.all(
                  color: ayahMarkerColor,
                  width: 1.2,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ayahMarkerColor.withOpacity(0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                '\u06DD${toArabicNumber(verse.number)}',
                style: TextStyle(
                  fontFamily: 'Kitab',
                  fontSize: themeProvider.arabicFontSize - 2,
                  color: ayahMarkerColor,
                ),
              ),
            ),
          ),
        ),
      );
      ayahSpans.add(const TextSpan(text: ' '));
    }
    return Container(
      color: isDark ? const Color(0xFF181818) : const Color(0xFFFFF8E1),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Surah header with decorative image
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/head.png',
                    height: 60,
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    color: isDark ? Colors.white : null,
                    colorBlendMode: isDark ? BlendMode.srcIn : BlendMode.dst,
                  ),
                  Text(
                    widget.surahName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFamily: 'Kitab',
                      fontWeight: FontWeight.bold,
                      fontSize: surahNameFontSize,
                      color: surahNameColor,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_ayahs.isNotEmpty && widget.surahNumber != 1 && widget.surahNumber != 9)
              Center(
                child: Image.asset(
                  basmallahImagePath,
                  height: 50.0,
                  fit: BoxFit.contain,
                  color: themeProvider.getReadingModeTextColor(context),
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
            const SizedBox(height: 24),
            // Quranic text block
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                text: TextSpan(children: ayahSpans),
                textAlign: TextAlign.justify,
              ),
            ),
            // Translation and Tafsir (optional, below the Quranic text)
            if (prefProvider.showTranslation && _translations != null)
              ..._ayahs.map((verse) {
                final translation = _translations!.translations.firstWhere(
                  (t) => t.number == verse.number,
                  orElse: () => Translation(number: verse.number, text: '', edition: '', language: ''),
                );
                return translation.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12, right: 8, left: 8),
                        child: Text(
                          '${verse.number}. ${translation.text}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            if (prefProvider.showTafsir && _tafsir != null)
              ..._ayahs.map((verse) {
                final tafsir = _tafsir!.tafasir.firstWhere(
                  (t) => t.ayahNumber == verse.number,
                  orElse: () => Tafsir(ayahNumber: verse.number, text: '', author: '', language: ''),
                );
                return tafsir.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
                        child: Text(
                          '${verse.number}. ${tafsir.text}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            // TODO: Add audio quality/reciter selection setting for improved sound
          ],
        ),
      ),
    );
  }

  Widget _buildAyahActionMenu(BuildContext context, Verse verse, bool isPlaying) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
            title: Text(isPlaying ? 'Pause Audio' : 'Play Audio'),
            onTap: () {
              Navigator.pop(context);
              if (isPlaying) {
                _stopAudio();
              } else {
                _playAudio(verse.number);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_add_rounded),
            title: const Text('Bookmark Ayah'),
            onTap: () {
              Navigator.pop(context);
              _showBookmarkDialog(verse);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Mark as Last Read'),
            onTap: () {
              Provider.of<ReadingProgressProvider>(context, listen: false).updateProgress(
                widget.surahNumber,
                widget.surahName,
                verse.number,
                _ayahs.length,
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefProvider = Provider.of<PreferenceSettingsProvider>(context);
    final progressProvider = Provider.of<ReadingProgressProvider>(context);
    final themeProvider = Provider.of<EnhancedThemeProvider>(context);
    final progress = progressProvider.getProgress(widget.surahNumber);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: themeProvider.getReadingModeBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          widget.surahName,
          style: TextStyle(
            color: themeProvider.getReadingModeTextColor(context),
          ),
        ),
        backgroundColor: themeProvider.getReadingModeBackgroundColor(context),
        iconTheme: IconThemeData(
          color: themeProvider.getReadingModeTextColor(context),
        ),
        actions: [
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildReadingControls(prefProvider),
                isScrollControlled: true,
              );
            },
          ),
          // Theme Toggle
          IconButton(
            icon: Icon(
              themeProvider.isDarkTheme(context) ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.setThemeMode(
                themeProvider.isDarkTheme(context) ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
              ? Center(
                  child: Text(
                    'Failed to load ayahs. Please try again later.',
                    style: TextStyle(
                      color: themeProvider.getReadingModeTextColor(context),
                      fontSize: 16.0,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Reading Progress Indicator
                    if (progress != null)
                      Consumer<EnhancedThemeProvider>(
                        builder: (context, themeProvider, child) {
                          final isDarkTheme = themeProvider.isDarkTheme(context);
                          return Container(
                            margin: const EdgeInsets.all(16.0),
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: themeProvider.getReadingModeCardColor(context),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.bookmark,
                                    color: theme.colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Continue Reading',
                                        style: TextStyle(
                                          color: themeProvider.getReadingModeTextColor(context),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Last read: Ayah ${progress.lastReadAyah}',
                                        style: TextStyle(
                                          color: themeProvider.getReadingModeTextColor(context).withOpacity(0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '${progress.progressPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 60,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: progress.progressPercentage / 100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    // Quran page layout
                    Expanded(
                      child: _buildQuranPage(context, prefProvider),
                    ),
                  ],
                ),
    );
  }
}
