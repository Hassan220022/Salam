import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/surah_entity.dart';
import '../providers/preference_settings_provider.dart';
import '../providers/surah_provider.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({Key? key}) : super(key: key);

  @override
  _QuranReaderScreenState createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  List<Verse> _allVerses = [];
  bool _isLoading = true;
  bool _isError = false;

  // Define the Basmallah text to filter out
  static const String basmallahText = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ";

  @override
  void initState() {
    super.initState();
    _loadAllVerses();
  }

  Future<void> _loadAllVerses() async {
    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      final surahProvider = context.read<SurahProvider>();

      // Load all surahs if not already loaded
      if (surahProvider.surahs.isEmpty) {
        await surahProvider.loadAllSurahs();
      }

      // Extract all verses from all surahs
      List<Verse> allVerses = [];
      for (final surah in surahProvider.surahs) {
        for (final verse in surah.verses) {
          // Skip verses that exactly match the Basmallah text
          if (verse.arabicText.trim() != basmallahText.trim()) {
            allVerses.add(verse);
          }
        }
      }

      setState(() {
        _allVerses = allVerses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<SurahProvider, PreferenceSettingsProvider>(
        builder: (context, surahProvider, preferenceProvider, child) {
          final theme = Theme.of(context);

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load Quran. Please try again later.',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAllVerses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Basmallah Image at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/basmallah.png',
                  height: 50.0,
                  fit: BoxFit.contain,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Divider(),
              // Expanded ListView to display all verses
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAllVerses,
                  child: ListView.builder(
                    itemCount: _allVerses.length,
                    itemBuilder: (context, index) {
                      final verse = _allVerses[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              verse.number.toString(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            verse.arabicText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'Roboto',
                            ),
                            textAlign: TextAlign.right,
                          ),
                          subtitle: verse.hasTranslation
                              ? Text(
                                  verse.translation!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
