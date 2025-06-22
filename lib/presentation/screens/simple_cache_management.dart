import 'package:flutter/material.dart';
import '../../services/auto_cache_service.dart';

class SimpleCacheManagementScreen extends StatefulWidget {
  const SimpleCacheManagementScreen({super.key});

  @override
  State<SimpleCacheManagementScreen> createState() =>
      _SimpleCacheManagementScreenState();
}

class _SimpleCacheManagementScreenState
    extends State<SimpleCacheManagementScreen> {
  Map<String, dynamic> _cacheInfo = {};
  bool _isLoading = false;
  int _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheInfo = await AutoCacheService.getCacheInfo();
      setState(() {
        _cacheInfo = cacheInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cacheCommonSurahs() async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0;
    });

    try {
      await AutoCacheService.cacheCommonSurahs(
        onProgress: (current, total) {
          setState(() {
            _downloadProgress = current;
          });
        },
      );
      await _loadCacheInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Common surahs (14) cached for offline reading'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cache surahs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
      _downloadProgress = 0;
    });
  }

  Future<void> _cacheAllSurahs() async {
    final shouldCache = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache All Surahs'),
        content: const Text(
          'This will download all 114 surahs for complete offline access. '
          'This may take several minutes and use considerable storage space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Download All'),
          ),
        ],
      ),
    );

    if (shouldCache == true) {
      setState(() {
        _isLoading = true;
        _downloadProgress = 0;
      });

      try {
        await AutoCacheService.cacheAllSurahs(
          onProgress: (current, total) {
            setState(() {
              _downloadProgress = current;
            });
          },
        );
        await _loadCacheInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('All surahs (114) cached! Full offline access enabled.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cache all surahs: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
        _downloadProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cache & Offline',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF091945),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF091945)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading cache information...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCacheInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cache Overview Card
                    _buildCacheOverviewCard(),
                    const SizedBox(height: 16),

                    // Offline Status Card
                    _buildOfflineStatusCard(),
                    const SizedBox(height: 16),

                    // Cache Actions Card
                    _buildCacheActionsCard(),
                    const SizedBox(height: 16),

                    // Information Card
                    _buildInfoCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCacheOverviewCard() {
    final cachedSurahs = _cacheInfo['cached_surahs'] ?? 0;
    final cacheSize = _cacheInfo['cache_size_kb'] ?? '0.00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.storage,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 16),
              Text(
                'Cache Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCacheMetric(
                  'Cached Surahs',
                  '$cachedSurahs',
                  Icons.book,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCacheMetric(
                  'Storage Used',
                  '$cacheSize KB',
                  Icons.storage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCacheMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatusCard() {
    final offlineStatus = _cacheInfo['offline_status'] ?? 'No offline content';
    final hasOfflineContent = _cacheInfo['cached_surahs'] > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasOfflineContent
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (hasOfflineContent ? Colors.green : Colors.orange)
                .withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasOfflineContent ? Icons.offline_pin : Icons.cloud_off,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasOfflineContent ? 'Offline Ready' : 'Online Only',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  offlineStatus,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.settings,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 16),
              Text(
                'Cache Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Preload Popular Surahs Button (9 surahs)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        await AutoCacheService.preloadPopularSurahs();
                        await _loadCacheInfo();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Popular surahs (9) cached for offline reading'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to cache surahs: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }

                      setState(() {
                        _isLoading = false;
                      });
                    },
              icon: const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Cache Popular Surahs (9)',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cache Common Surahs Button (14 surahs)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _cacheCommonSurahs,
              icon: const Icon(Icons.library_books, color: Colors.white),
              label: const Text(
                'Cache Common Surahs (14)',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cache All Surahs Button (114 surahs)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _cacheAllSurahs,
              icon: const Icon(Icons.cloud_download, color: Colors.white),
              label: Text(
                _isLoading && _downloadProgress > 0
                    ? 'Caching All Surahs... $_downloadProgress/114'
                    : 'Cache All Surahs (114) - Full Offline',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Clear Cache Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final shouldClear = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Cache'),
                          content: const Text(
                            'This will delete all cached Quran content. You\'ll need an internet connection to download them again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Clear Cache'),
                            ),
                          ],
                        ),
                      );

                      if (shouldClear == true) {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          await AutoCacheService.clearAllCache();
                          await _loadCacheInfo();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cache cleared successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to clear cache: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }

                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              label: const Text(
                'Clear All Cache',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFF091945),
                size: 28,
              ),
              SizedBox(width: 16),
              Text(
                'About Permanent Caching',
                style: TextStyle(
                  color: Color(0xFF091945),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '• Surahs are automatically cached when you read them\n'
            '• Cached content remains until you manually remove it\n'
            '• No automatic expiration - permanent offline storage\n'
            '• Download once, read forever without internet\n'
            '• Cache is stored using device\'s secure storage',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
