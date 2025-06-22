import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../domain/entities/surah_entity.dart';
import '../providers/preference_settings_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/surah_provider.dart';

import '../../data/models/translation.dart';
import '../../data/models/tafsir.dart';
import '../../services/audio_player_service.dart';
import '../../services/quran_service.dart';

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

    // Set up scroll listener for progress tracking
    _scrollController.addListener(_onScroll);
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.bookmark_add,
                      color: Colors.white,
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Save this verse for later',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Verse preview card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.surahName} ${verse.number}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verse.arabicText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
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
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
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
                    child: FilledButton(
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
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bookmark_add, size: 20),
                          const SizedBox(width: 8),
                          const Text('Save Bookmark'),
                        ],
                      ),
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

  void _onScroll() {
    if (!mounted || _ayahs.isEmpty) return;

    final progressProvider =
        Provider.of<ReadingProgressProvider>(context, listen: false);

    // Get the current scroll position
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final totalScrollableHeight = _scrollController.position.maxScrollExtent;

    // Calculate which verse is currently in the middle of the viewport
    // This gives us a more accurate representation of reading progress
    final middleOfViewport = scrollOffset + (viewportHeight / 2);

    // Calculate progress as percentage of scroll completion
    double scrollProgress = 0.0;
    if (totalScrollableHeight > 0) {
      scrollProgress = (scrollOffset / totalScrollableHeight).clamp(0.0, 1.0);
    }

    // If user has scrolled to the very bottom, mark as completed
    if (scrollOffset >= totalScrollableHeight - 10) {
      // 10px threshold for bottom detection
      // Mark as fully completed - this will trigger auto-removal in the provider
      if (_lastReportedAyah != _totalAyahs) {
        _lastReportedAyah = _totalAyahs;
        progressProvider.updateProgress(
          widget.surahNumber,
          widget.surahName,
          _totalAyahs, // Set to total ayahs to indicate completion
          _totalAyahs,
        );
      }
      return;
    }

    // Convert scroll progress to ayah number
    // Add 1 because we want to show that we're reading verse X, not that we've completed X-1 verses
    final currentAyah =
        ((scrollProgress * _totalAyahs) + 1).round().clamp(1, _totalAyahs);

    // Only update if the ayah has changed and is valid
    if (currentAyah > 0 &&
        currentAyah <= _totalAyahs &&
        currentAyah != _lastReportedAyah) {
      _lastReportedAyah = currentAyah;
      progressProvider.updateProgress(
        widget.surahNumber,
        widget.surahName,
        currentAyah,
        _totalAyahs,
      );
    }
  }

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
    required bool isDarkTheme,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkTheme
                    ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                    : [const Color(0xFFfafafa), Colors.white],
              ),
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
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Select Option',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme ? Colors.white : Colors.black87,
                        ),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              onSelected(entry.key);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          color.withValues(alpha: 0.2),
                                          color.withValues(alpha: 0.1),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: isDarkTheme
                                            ? [
                                                const Color(0xFF2a2a3e),
                                                const Color(0xFF1e1e2e)
                                              ]
                                            : [
                                                Colors.white,
                                                const Color(0xFFf8f9fa)
                                              ],
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.5)
                                      : (isDarkTheme
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.2)),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isDarkTheme
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkTheme
                ? [const Color(0xFF3a3a4e), const Color(0xFF2e2e3e)]
                : [Colors.white, const Color(0xFFf8f9fa)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkTheme
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isDarkTheme ? Colors.white70 : Colors.grey[600],
            ),
          ],
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
    final isDarkTheme = prefProvider.isDarkTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkTheme
              ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
              : [const Color(0xFFf8f9fa), const Color(0xFFe9ecef)],
        ),
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
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Reading Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
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
                  _buildSettingsCard(
                    icon: Icons.format_size,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Font Size',
                    subtitle: '${prefProvider.arabicFontSize.round()}px',
                    child: Slider(
                      value: prefProvider.arabicFontSize,
                      min: 14.0,
                      max: 32.0,
                      divisions: 18,
                      activeColor: const Color(0xFF4CAF50),
                      inactiveColor: Colors.grey[300],
                      onChanged: (value) {
                        prefProvider.setArabicFontSize(value);
                      },
                    ),
                    isDarkTheme: isDarkTheme,
                  ),

                  const SizedBox(height: 16),

                  // Night Reading Mode
                  _buildSettingsCard(
                    icon: Icons.nightlight_round,
                    iconColor: const Color(0xFF9C27B0),
                    title: 'Night Reading Mode',
                    subtitle: 'Dimmed screen for comfortable reading',
                    child: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: prefProvider.isNightReadingMode,
                        onChanged: (value) {
                          prefProvider.enableNightReadingMode(value);
                          if (value && _originalBrightness != null) {
                            ScreenBrightness().setScreenBrightness(0.3);
                          } else if (_originalBrightness != null) {
                            ScreenBrightness()
                                .setScreenBrightness(_originalBrightness!);
                          }
                        },
                        activeColor: const Color(0xFF9C27B0),
                      ),
                    ),
                    isDarkTheme: isDarkTheme,
                  ),

                  const SizedBox(height: 16),

                  // Translation Section
                  _buildSettingsCard(
                    icon: Icons.translate,
                    iconColor: const Color(0xFF2196F3),
                    title: 'Translation',
                    subtitle:
                        prefProvider.showTranslation ? 'Enabled' : 'Disabled',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Show Translation'),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: prefProvider.showTranslation,
                                onChanged: (value) {
                                  prefProvider.toggleTranslation(value);
                                  if (value) _loadTranslations();
                                },
                                activeColor: const Color(0xFF2196F3),
                              ),
                            ),
                          ],
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
                            isDarkTheme: isDarkTheme,
                            icon: Icons.translate,
                            color: const Color(0xFF2196F3),
                          ),
                        ],
                      ],
                    ),
                    isDarkTheme: isDarkTheme,
                  ),

                  const SizedBox(height: 16),

                  // Tafsir Section
                  _buildSettingsCard(
                    icon: Icons.menu_book,
                    iconColor: const Color(0xFFFF9800),
                    title: 'Tafsir (Commentary)',
                    subtitle: prefProvider.showTafsir ? 'Enabled' : 'Disabled',
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Show Commentary'),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: prefProvider.showTafsir,
                                onChanged: (value) {
                                  prefProvider.toggleTafsir(value);
                                  if (value) _loadTafsir();
                                },
                                activeColor: const Color(0xFFFF9800),
                              ),
                            ),
                          ],
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
                            isDarkTheme: isDarkTheme,
                            icon: Icons.menu_book,
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ],
                    ),
                    isDarkTheme: isDarkTheme,
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
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    required bool isDarkTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                      ),
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
    );
  }

  Widget _buildAyahWidget(
      Verse verse, int index, PreferenceSettingsProvider prefProvider) {
    final isDarkTheme = prefProvider.isDarkTheme;
    final isHighlighted =
        widget.highlightAyah != null && verse.number == widget.highlightAyah;
    final isPlaying = _currentlyPlayingAyah == verse.number;

    // Get translation for this ayah
    Translation? translation;
    if (_translations != null) {
      try {
        translation = _translations!.translations.firstWhere(
          (t) => t.number == verse.number,
        );
      } catch (e) {
        // Translation not found
      }
    }

    // Get tafsir for this ayah
    Tafsir? tafsir;
    if (_tafsir != null) {
      try {
        tafsir = _tafsir!.tafasir.firstWhere(
          (t) => t.ayahNumber == verse.number,
        );
      } catch (e) {
        // Tafsir not found
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                colors: [
                  const Color(0xFFFFF59D).withValues(alpha: 0.8),
                  const Color(0xFFFFE082).withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: isDarkTheme
                    ? [const Color(0xFF2a2a3e), const Color(0xFF1e1e2e)]
                    : [Colors.white, const Color(0xFFfafafa)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: isDarkTheme
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        border: isHighlighted
            ? Border.all(color: const Color(0xFFFFB300), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header with Ayah Number
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                // Beautiful Ayah Number
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPlaying
                          ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                          : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isPlaying
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF667eea))
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      verse.number.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Action Buttons with Beautiful Styling
                Row(
                  children: [
                    // Audio Control
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkTheme
                            ? Colors.grey[700]?.withValues(alpha: 0.5)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: isPlaying
                              ? const Color(0xFF4CAF50)
                              : (isDarkTheme
                                  ? Colors.white70
                                  : const Color(0xFF667eea)),
                          size: 28,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            _stopAudio();
                          } else {
                            _playAudio(verse.number);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Bookmark Button
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkTheme
                            ? Colors.grey[700]?.withValues(alpha: 0.5)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.bookmark_add_rounded,
                          color: isDarkTheme
                              ? Colors.white70
                              : const Color(0xFFFF9800),
                          size: 24,
                        ),
                        onPressed: () => _showBookmarkDialog(verse),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Decorative Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDarkTheme ? Colors.white24 : Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Arabic Text with Beautiful Typography
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  verse.arabicText,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: prefProvider.arabicFontSize,
                    height: 2.0,
                    fontWeight: FontWeight.w500,
                    color: isDarkTheme ? Colors.white : const Color(0xFF1a1a2e),
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),

                // Decorative ornament
                if (!prefProvider.showTranslation && !prefProvider.showTafsir)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: 80,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey[400]!,
                          Colors.transparent
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),

          // Translation with Beautiful Styling
          if (prefProvider.showTranslation && translation != null)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkTheme
                      ? [
                          const Color(0xFF1565C0).withValues(alpha: 0.2),
                          const Color(0xFF0D47A1).withValues(alpha: 0.1)
                        ]
                      : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF2196F3).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.translate,
                              size: 14,
                              color: isDarkTheme
                                  ? Colors.white
                                  : const Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Translation',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkTheme
                                    ? Colors.white
                                    : const Color(0xFF1976D2),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    translation.text,
                    style: TextStyle(
                      fontSize: 16.0,
                      height: 1.6,
                      color:
                          isDarkTheme ? Colors.white : const Color(0xFF424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

          // Tafsir with Beautiful Styling
          if (prefProvider.showTafsir)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkTheme
                      ? [
                          const Color(0xFF388E3C).withValues(alpha: 0.2),
                          const Color(0xFF2E7D32).withValues(alpha: 0.1)
                        ]
                      : [const Color(0xFFE8F5E8), const Color(0xFFC8E6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 14,
                              color: isDarkTheme
                                  ? Colors.white
                                  : const Color(0xFF388E3C),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Commentary',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkTheme
                                    ? Colors.white
                                    : const Color(0xFF388E3C),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Show tafsir text if available, otherwise show helpful message
                  if (tafsir != null && tafsir.text.isNotEmpty)
                    Text(
                      tafsir.text,
                      style: TextStyle(
                        fontSize: 14.0,
                        height: 1.5,
                        color: isDarkTheme
                            ? Colors.white70
                            : const Color(0xFF424242),
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: isDarkTheme
                                  ? Colors.white60
                                  : const Color(0xFF666666),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Commentary not available',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                                color: isDarkTheme
                                    ? Colors.white60
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tafsir for this verse is not available in the selected commentary. Try switching to a different tafsir source in settings.',
                          style: TextStyle(
                            fontSize: 12.0,
                            height: 1.4,
                            color: isDarkTheme
                                ? Colors.white.withValues(alpha: 0.5)
                                : const Color(0xFF888888),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefProvider = Provider.of<PreferenceSettingsProvider>(context);
    final progressProvider = Provider.of<ReadingProgressProvider>(context);
    final isDarkTheme = prefProvider.isDarkTheme;
    final progress = progressProvider.getProgress(widget.surahNumber);

    return Scaffold(
      backgroundColor: prefProvider.isNightReadingMode
          ? Colors.black
          : (isDarkTheme ? const Color(0xFF091945) : Colors.white),
      appBar: AppBar(
        title: Text(
          widget.surahName,
          style: TextStyle(
            color: isDarkTheme ? Colors.white : const Color(0xff682DBD),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(
          color: isDarkTheme ? Colors.white : const Color(0xff682DBD),
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
              isDarkTheme ? Icons.light_mode : Icons.dark_mode,
              color: isDarkTheme ? Colors.white : const Color(0xff682DBD),
            ),
            onPressed: () {
              prefProvider.enableDarkTheme(!isDarkTheme);
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
                      color: isDarkTheme ? Colors.white : Colors.black,
                      fontSize: 16.0,
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Reading Progress Indicator
                    if (progress != null)
                      Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkTheme
                                ? [
                                    const Color(0xFF2a2a3e),
                                    const Color(0xFF1e1e2e)
                                  ]
                                : [
                                    const Color(0xFFE8F4FD),
                                    const Color(0xFFD1E9F6)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkTheme
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.grey.withValues(alpha: 0.1),
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
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2196F3),
                                    const Color(0xFF1976D2)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.bookmark,
                                color: Colors.white,
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
                                      color: isDarkTheme
                                          ? Colors.white
                                          : const Color(0xFF1976D2),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last read: Ayah ${progress.lastReadAyah}',
                                    style: TextStyle(
                                      color: isDarkTheme
                                          ? Colors.white70
                                          : const Color(0xFF424242),
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
                                    color: isDarkTheme
                                        ? Colors.white
                                        : const Color(0xFF1976D2),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDarkTheme
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor:
                                        progress.progressPercentage / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF2196F3),
                                            const Color(0xFF1976D2)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Content
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _ayahs.length + 1, // +1 for Basmallah
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ColorFiltered(
                                colorFilter: isDarkTheme
                                    ? const ColorFilter.mode(
                                        Colors.transparent, BlendMode.multiply)
                                    : const ColorFilter.matrix([
                                        -1,
                                        0,
                                        0,
                                        0,
                                        255,
                                        0,
                                        -1,
                                        0,
                                        0,
                                        255,
                                        0,
                                        0,
                                        -1,
                                        0,
                                        255,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                      ]),
                                child: Image.asset(
                                  basmallahImagePath,
                                  height: 50.0,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          }

                          final verse = _ayahs[index - 1];
                          return _buildAyahWidget(
                              verse, index - 1, prefProvider);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
