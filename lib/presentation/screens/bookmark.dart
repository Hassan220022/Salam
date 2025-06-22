import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../providers/bookmarks_provider.dart';
import '../providers/preference_settings_provider.dart';
import 'surah_reader.dart';
import 'main_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({Key? key}) : super(key: key);

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _floatingButtonController;

  @override
  void initState() {
    super.initState();
    _floatingButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _floatingButtonController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _floatingButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkTheme
                ? [colorScheme.surface, colorScheme.surfaceContainerHighest]
                : [colorScheme.surface, colorScheme.surfaceContainerHighest],
          ),
        ),
        child: Consumer2<BookmarksProvider, PreferenceSettingsProvider>(
          builder: (context, bookmarksProvider, preferenceProvider, child) {
            final allBookmarks = bookmarksProvider.bookmarks;
            final filteredBookmarks = _searchQuery.isEmpty
                ? allBookmarks
                : allBookmarks
                    .where((bookmark) =>
                        bookmark.surahName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        bookmark.arabicText.contains(_searchQuery) ||
                        (bookmark.note
                                ?.toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ??
                            false))
                    .toList();

            if (bookmarksProvider.isLoading) {
              return _buildLoadingState();
            }

            return CustomScrollView(
              slivers: [
                // Beautiful header
                _buildModernHeader(colorScheme),

                // Search section
                _buildSearchSection(colorScheme),

                // Statistics card (enhanced)
                if (allBookmarks.isNotEmpty)
                  _buildEnhancedStatsCard(allBookmarks, colorScheme),

                // Quick actions section
                // if (allBookmarks.isNotEmpty)
                //   _buildQuickActionsSection(colorScheme),

                // Empty state or bookmarks list
                if (filteredBookmarks.isEmpty)
                  SliverFillRemaining(
                    child: _buildModernEmptyState(colorScheme),
                  )
                else
                  _buildBookmarksList(filteredBookmarks, bookmarksProvider),

                const SliverToBoxAdapter(
                  child: SizedBox(
                      height: 120), // Bottom padding for floating action
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Consumer<BookmarksProvider>(
        builder: (context, bookmarksProvider, child) {
          return bookmarksProvider.bookmarks.isEmpty
              ? const SizedBox.shrink()
              : ScaleTransition(
                  scale: _floatingButtonController,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Continue Reading'),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 8,
                  ),
                );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading your bookmarks...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preparing your saved verses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.bookmarks_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Bookmarks',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your saved verses and reflections',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.1,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search bookmarks, verses, or notes...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatsCard(List allBookmarks, ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF667eea),
                const Color(0xFF764ba2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Reading Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.bookmark_rounded,
                      value: allBookmarks.length.toString(),
                      label: 'Total\nBookmarks',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.menu_book_rounded,
                      value: allBookmarks
                          .map((b) => b.surahNumber)
                          .toSet()
                          .length
                          .toString(),
                      label: 'Surahs\nCovered',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.note_rounded,
                      value: allBookmarks
                          .where((b) => b.note?.isNotEmpty == true)
                          .length
                          .toString(),
                      label: 'Personal\nNotes',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernEmptyState(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Icon(
                      _searchQuery.isEmpty
                          ? Icons.bookmark_border_rounded
                          : Icons.search_off_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isEmpty
                    ? 'No bookmarks yet'
                    : 'No bookmarks found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _searchQuery.isEmpty
                      ? 'Start your spiritual journey by reading and bookmarking meaningful verses'
                      : 'Try a different search term or check your spelling',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 32),
              if (_searchQuery.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Start Reading',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24), // Extra padding at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksList(
      List filteredBookmarks, BookmarksProvider bookmarksProvider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: AnimationLimiter(
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final bookmark = filteredBookmarks[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child:
                        _buildEnhancedBookmarkCard(bookmark, bookmarksProvider),
                  ),
                ),
              );
            },
            childCount: filteredBookmarks.length,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedBookmarkCard(
      bookmark, BookmarksProvider bookmarksProvider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Dismissible(
        key: Key('${bookmark.surahNumber}_${bookmark.verseNumber}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onDismissed: (direction) {
          bookmarksProvider.removeBookmark(
            surahNumber: bookmark.surahNumber,
            verseNumber: bookmark.verseNumber,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Bookmark removed successfully'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahReaderScreen(
                      surahNumber: bookmark.surahNumber,
                      surahName: bookmark.surahName,
                      highlightAyah: bookmark.verseNumber,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bookmark.verseNumber.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookmark.surahName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.bookmark_rounded,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verse ${bookmark.verseNumber}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Surah ${bookmark.surahNumber}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.05),
                            colorScheme.secondary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bookmark.arabicText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'Quran',
                              fontSize: 20,
                              height: 2.0,
                              letterSpacing: 0.5,
                            ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    if (bookmark.translation != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          bookmark.translation!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                    height: 1.6,
                                  ),
                        ),
                      ),
                    ],
                    if (bookmark.note != null && bookmark.note!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.note_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Note',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bookmark.note!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                          height: 1.4,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(bookmark.createdAt),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurahReaderScreen(
                                    surahNumber: bookmark.surahNumber,
                                    surahName: bookmark.surahName,
                                    highlightAyah: bookmark.verseNumber,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 11,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
