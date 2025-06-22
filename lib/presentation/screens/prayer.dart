import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math' as math;
import '../providers/preference_settings_provider.dart';
import '../widgets/enhanced_loading.dart';

class PrayerTimeService {
  Future<Map<String, dynamic>> getPrayerTimes(String latitude, String longitude,
      {DateTime? date}) async {
    String dateString = '';
    if (date != null) {
      dateString =
          '&date=${date.day}-${date.month}-${date.year}'; // Format as DD-MM-YYYY
    }

    final url =
        'https://api.aladhan.com/v1/timings?latitude=$latitude&longitude=$longitude$dateString';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['timings'];
    } else {
      throw Exception('Failed to load prayer times: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getIslamicCalendar({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final url =
        'https://api.aladhan.com/v1/gToH/${targetDate.day}-${targetDate.month}-${targetDate.year}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['hijri'];
      } else {
        throw Exception('Failed to load Islamic calendar');
      }
    } catch (e) {
      throw Exception('Error fetching Islamic calendar: $e');
    }
  }

  double calculateQiblaDirection(double lat, double lng) {
    // Kaaba coordinates
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;

    // Convert to radians
    final double latRad = lat * (math.pi / 180);
    final double lngRad = lng * (math.pi / 180);
    final double kaabaLatRad = kaabaLat * (math.pi / 180);
    final double kaabaLngRad = kaabaLng * (math.pi / 180);

    final double dLng = kaabaLngRad - lngRad;

    final double y = math.sin(dLng) * math.cos(kaabaLatRad);
    final double x = math.cos(latRad) * math.sin(kaabaLatRad) -
        math.sin(latRad) * math.cos(kaabaLatRad) * math.cos(dLng);

    double bearing = math.atan2(y, x);
    bearing = bearing * (180 / math.pi);
    bearing = (bearing + 360) % 360;

    return bearing;
  }
}

class PrayerTimesWidget extends StatefulWidget {
  const PrayerTimesWidget({super.key});

  @override
  _PrayerTimesWidgetState createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget>
    with TickerProviderStateMixin {
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  Map<String, dynamic>? _prayerTimes;
  Map<String, dynamic>? _islamicCalendar;
  bool _isLoading = true;
  Position? _currentPosition;
  String? _nextPrayer;
  String? _nextPrayerTime;
  Duration? _timeLeft;
  String? _errorMessage;
  double? _qiblaDirection;
  late AnimationController _animationController;
  late AnimationController _qiblaController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _qiblaAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _qiblaController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _qiblaAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _qiblaController, curve: Curves.elasticOut),
    );
    _determinePosition();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _qiblaController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Location services are disabled. Please enable location services.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Location permission denied. Please grant location permission.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Location permission permanently denied. Please enable in settings.';
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      await _fetchAllData();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting location: $e');
      }
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to get your location. Please check your location settings.';
      });
    }
  }

  Future<void> _fetchAllData() async {
    if (_currentPosition == null) return;

    try {
      // Fetch prayer times, Islamic calendar, and calculate Qibla direction in parallel
      final results = await Future.wait([
        _prayerTimeService.getPrayerTimes(
          _currentPosition!.latitude.toString(),
          _currentPosition!.longitude.toString(),
        ),
        _prayerTimeService.getIslamicCalendar(),
      ]);

      final timings = results[0] as Map<String, dynamic>;
      final islamicCalendar = results[1] as Map<String, dynamic>;

      // Format the prayer times
      DateFormat inputFormat = DateFormat("HH:mm");
      DateFormat outputFormat = DateFormat("h:mm a");

      final formattedTimings = <String, dynamic>{};
      timings.forEach((key, value) {
        try {
          DateTime time = inputFormat.parse(value);
          String formattedTime = outputFormat.format(time);
          formattedTimings[key] = formattedTime;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing time for $key: $value - $e');
          }
          formattedTimings[key] = "Invalid Time";
        }
      });

      // Calculate Qibla direction
      final qiblaDirection = _prayerTimeService.calculateQiblaDirection(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Get next prayer time
      await _getNextPrayerTime(formattedTimings);

      if (mounted) {
        setState(() {
          _prayerTimes = formattedTimings;
          _islamicCalendar = islamicCalendar;
          _qiblaDirection = qiblaDirection;
          _isLoading = false;
          _errorMessage = null;
        });
        _animationController.forward();
        _qiblaController.forward();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching data: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to load data. Please check your internet connection.';
        });
      }
    }
  }

  Future<void> _getNextPrayerTime(Map<String, dynamic> timings) async {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat("h:mm a");
    DateTime? nextPrayerTime;
    String? nextPrayer;

    // Prayer names in order
    final prayerNames = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];

    // Iterate over today's prayers to find the next prayer
    for (var prayerName in prayerNames) {
      if (timings.containsKey(prayerName)) {
        try {
          DateTime prayerTime = formatter.parse(timings[prayerName]);
          DateTime combinedPrayerTime = DateTime(
            now.year,
            now.month,
            now.day,
            prayerTime.hour,
            prayerTime.minute,
          );

          if (combinedPrayerTime.isBefore(now)) {
            continue;
          }

          if (nextPrayerTime == null ||
              combinedPrayerTime.isBefore(nextPrayerTime)) {
            nextPrayerTime = combinedPrayerTime;
            nextPrayer = prayerName;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'Error parsing prayer time for $prayerName: ${timings[prayerName]} - $e');
          }
        }
      }
    }

    // If no next prayer today, fetch tomorrow's first prayer
    if (nextPrayerTime == null) {
      try {
        DateTime tomorrow = now.add(const Duration(days: 1));
        Map<String, dynamic> tomorrowTimings =
            await _prayerTimeService.getPrayerTimes(
          _currentPosition!.latitude.toString(),
          _currentPosition!.longitude.toString(),
          date: tomorrow,
        );

        // Format timings for tomorrow
        final formattedTomorrowTimings = <String, dynamic>{};
        tomorrowTimings.forEach((key, value) {
          try {
            DateTime time = DateFormat("HH:mm").parse(value);
            String formattedTime = formatter.format(time);
            formattedTomorrowTimings[key] = formattedTime;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error parsing tomorrow time for $key: $value - $e');
            }
            formattedTomorrowTimings[key] = "Invalid Time";
          }
        });

        // Get the first prayer of tomorrow
        for (var prayerName in prayerNames) {
          if (formattedTomorrowTimings.containsKey(prayerName)) {
            try {
              DateTime prayerTime =
                  formatter.parse(formattedTomorrowTimings[prayerName]);
              nextPrayerTime = DateTime(
                tomorrow.year,
                tomorrow.month,
                tomorrow.day,
                prayerTime.hour,
                prayerTime.minute,
              );
              nextPrayer = prayerName;
              break;
            } catch (e) {
              if (kDebugMode) {
                debugPrint(
                    'Error parsing tomorrow prayer time for $prayerName: ${formattedTomorrowTimings[prayerName]} - $e');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error fetching tomorrow prayer times: $e');
        }
        // Fallback to default values
        _nextPrayer = "No upcoming prayers";
        _nextPrayerTime = "Not available";
        _timeLeft = Duration.zero;
        return;
      }
    }

    // Calculate time left until next prayer
    if (nextPrayerTime != null) {
      _timeLeft = nextPrayerTime.difference(now);
      _nextPrayer = nextPrayer;
      _nextPrayerTime = formatter.format(nextPrayerTime);
    } else {
      _timeLeft = Duration.zero;
      _nextPrayer = "No upcoming prayers";
      _nextPrayerTime = "Not available";
    }
  }

  Future<void> _refreshPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: EnhancedLoading(
                message: 'Loading Islamic Services...',
                style: LoadingStyle.prayerStyle,
              ),
            )
          : _prayerTimes == null || _errorMessage != null
              ? _buildErrorState(context, colorScheme)
              : RefreshIndicator(
                  onRefresh: _refreshPrayerTimes,
                  color: colorScheme.primary,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Beautiful header with next prayer
                        SliverToBoxAdapter(
                          child: _buildPrayerHeader(context, colorScheme),
                        ),

                        // Prayer times grid
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: AnimationLimiter(
                            child: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final prayerEntries = _prayerTimes!.entries
                                      .where((entry) => ![
                                            "Firstthird",
                                            "Lastthird",
                                            "Midnight",
                                            "Imsak",
                                            "Sunset",
                                            "Sunrise",
                                          ].contains(entry.key))
                                      .toList();

                                  if (index >= prayerEntries.length)
                                    return null;

                                  final entry = prayerEntries[index];
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: _buildPrayerTimeCard(
                                          context,
                                          colorScheme,
                                          entry.key,
                                          entry.value,
                                          index,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: _prayerTimes!.entries
                                    .where((entry) => ![
                                          "Firstthird",
                                          "Lastthird",
                                          "Midnight",
                                          "Imsak",
                                          "Sunset",
                                          "Sunrise",
                                        ].contains(entry.key))
                                    .length,
                              ),
                            ),
                          ),
                        ),

                        // Islamic Calendar Section
                        if (_islamicCalendar != null) ...[
                          SliverToBoxAdapter(
                            child: _buildIslamicCalendarSection(
                                context, colorScheme),
                          ),
                        ],

                        // Qibla Direction Section
                        if (_qiblaDirection != null) ...[
                          SliverToBoxAdapter(
                            child: _buildQiblaSection(context, colorScheme),
                          ),
                        ],

                        // Bottom padding
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildIslamicCalendarSection(
      BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF11998e),
            const Color(0xFF38ef7d),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998e).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
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
                      'Islamic Calendar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Today\'s Hijri Date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_islamicCalendar!['day']} ${_islamicCalendar!['month']['en']}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      '${_islamicCalendar!['year']} AH',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _islamicCalendar!['month']['ar'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Quran',
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFf093fb),
            const Color(0xFFf5576c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFf093fb).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.explore_rounded,
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
                      'Qibla Direction',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Direction to Mecca',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _qiblaAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: (_qiblaDirection! * math.pi) / 180,
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_qiblaDirection!.toStringAsFixed(1)}°',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.errorContainer.withValues(alpha: 0.1),
              colorScheme.errorContainer.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Load Prayer Times',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshPrayerTimes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerHeader(BuildContext context, ColorScheme colorScheme) {
    String timeLeftString = _timeLeft != null
        ? "${_timeLeft!.inHours}h ${_timeLeft!.inMinutes.remainder(60)}m"
        : "Calculating...";

    final now = DateTime.now();
    final currentDate = DateFormat('EEEE, MMMM d, y').format(now);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Prayer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      _nextPrayer ?? "Loading...",
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                  Text(
                    _nextPrayerTime ?? "Loading...",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                  ),
                  Text(
                    timeLeftString,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentDate,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard(BuildContext context, ColorScheme colorScheme,
      String prayerName, String time, int index) {
    final isNext = prayerName == _nextPrayer;
    final prayerIcon = _getPrayerIcon(prayerName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNext
              ? [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                ]
              : [
                  colorScheme.surface,
                  colorScheme.surfaceContainer.withValues(alpha: 0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNext
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: isNext ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: isNext ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isNext
                  ? [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8)
                    ]
                  : [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: prayerIcon,
        ),
        title: Text(
          prayerName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isNext
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isNext
                ? colorScheme.primary.withValues(alpha: 0.2)
                : colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            time,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isNext ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
          ),
        ),
      ),
    );
  }

  Widget _getPrayerIcon(String prayerName) {
    IconData iconData;
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        iconData = Icons.wb_twilight;
        break;
      case 'dhuhr':
        iconData = Icons.wb_sunny;
        break;
      case 'asr':
        iconData = Icons.wb_sunny_outlined;
        break;
      case 'maghrib':
        iconData = Icons.wb_twilight_outlined;
        break;
      case 'isha':
        iconData = Icons.nightlight;
        break;
      default:
        iconData = Icons.access_time;
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: 24,
    );
  }
}
