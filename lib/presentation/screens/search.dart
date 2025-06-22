import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../domain/entities/surah_entity.dart';
import '../providers/surah_provider.dart';
import 'surah_reader.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Surah> _filteredSurahs = [];
  bool _isLoading = false;
  String _currentQuery = '';
  int _selectedSearchType = 0; // 0: All, 1: Meccan, 2: Medinan

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    setState(() => _isLoading = true);

    final surahProvider = context.read<SurahProvider>();
    if (surahProvider.surahs.isEmpty) {
      await surahProvider.loadAllSurahs();
    }

    setState(() {
      _filteredSurahs = surahProvider.surahs;
      _isLoading = false;
    });
  }

  void _performSearch(String query) {
    setState(() {
      _currentQuery = query;
      final surahProvider = context.read<SurahProvider>();
      final allSurahs = surahProvider.surahs;

      if (query.isEmpty) {
        _filteredSurahs = _applyFilter(allSurahs);
        return;
      }

      final searchResults = <Surah>[];
      final lowerQuery = query.toLowerCase();

      // Search by number
      final surahNumber = int.tryParse(query);
      if (surahNumber != null) {
        final surahByNumber = allSurahs.where(
          (surah) => surah.number == surahNumber,
        );
        searchResults.addAll(surahByNumber);
      }

      // Search by English name
      searchResults.addAll(allSurahs.where(
        (surah) => surah.englishName.toLowerCase().contains(lowerQuery),
      ));

      // Search by Arabic name
      searchResults.addAll(allSurahs.where(
        (surah) => surah.name.contains(query),
      ));

      // Search by English translation
      searchResults.addAll(allSurahs.where(
        (surah) =>
            surah.englishNameTranslation.toLowerCase().contains(lowerQuery),
      ));

      // Remove duplicates and apply filter
      final uniqueResults = searchResults.toSet().toList();
      _filteredSurahs = _applyFilter(uniqueResults);
    });
  }

  List<Surah> _applyFilter(List<Surah> surahs) {
    switch (_selectedSearchType) {
      case 1:
        return surahs.where((surah) => surah.isMeccan).toList();
      case 2:
        return surahs.where((surah) => surah.isMedinan).toList();
      default:
        return surahs;
    }
  }

  void _onFilterChanged(int index) {
    setState(() {
      _selectedSearchType = index;
      _performSearch(_currentQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Search
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 140,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667eea),
                      const Color(0xFF764ba2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Search Quran',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'Find surahs by name, number, or type',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(78),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Field
                    SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Search by name, number, or Arabic...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _currentQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Filter Tabs
                    SizedBox(
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          onTap: _onFilterChanged,
                          indicator: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          labelStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                          unselectedLabelStyle: const TextStyle(fontSize: 11),
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          labelPadding: EdgeInsets.zero,
                          tabs: const [
                            Tab(text: 'All'),
                            Tab(text: 'Meccan'),
                            Tab(text: 'Medinan'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search Results
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredSurahs.isEmpty && _currentQuery.isNotEmpty)
            SliverFillRemaining(
              child: _buildEmptySearchState(),
            )
          else if (_filteredSurahs.isEmpty)
            SliverFillRemaining(
              child: _buildInitialState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: AnimationLimiter(
                child: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final surah = _filteredSurahs[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildSurahCard(surah, index),
                          ),
                        ),
                      );
                    },
                    childCount: _filteredSurahs.length,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .errorContainer
                  .withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords\nor check your spelling',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              _performSearch('');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discover the Quran',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search through 114 surahs by name,\nnumber, or revelation type',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            children: [
              _buildSuggestionChip('Al-Fatiha'),
              _buildSuggestionChip('Al-Baqarah'),
              _buildSuggestionChip('114'),
              _buildSuggestionChip('Yasin'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return ActionChip(
      label: Text(suggestion),
      onPressed: () {
        _searchController.text = suggestion;
        _performSearch(suggestion);
      },
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildSurahCard(Surah surah, int index) {
    final isHighlighted = _currentQuery.isNotEmpty &&
        (surah.englishName
                .toLowerCase()
                .contains(_currentQuery.toLowerCase()) ||
            surah.name.contains(_currentQuery) ||
            surah.number.toString() == _currentQuery);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahReaderScreen(
                  surahNumber: surah.number,
                  surahName: surah.name,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Surah Number
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        surah.isMeccan
                            ? const Color(0xFF667eea)
                            : const Color(0xFF764ba2),
                        surah.isMeccan
                            ? const Color(0xFF764ba2)
                            : const Color(0xFF667eea),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      surah.number.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Surah Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              surah.englishName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isHighlighted
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: surah.isMeccan
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              surah.revelationType,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: surah.isMeccan
                                    ? Colors.orange[700]
                                    : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        surah.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Quran',
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${surah.numberOfAyahs} verses',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            surah.englishNameTranslation,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
