import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/qibla_service.dart';
import '../providers/preference_settings_provider.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with TickerProviderStateMixin {
  late QiblaProvider _qiblaProvider;
  late AnimationController _compassController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _qiblaProvider = QiblaProvider();
    _compassController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initializeQibla();
  }

  @override
  void dispose() {
    _compassController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeQibla() async {
    try {
      await _qiblaProvider.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Qibla Direction Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeQibla();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCalibrationInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.explore, color: Colors.blue),
            SizedBox(width: 8),
            Text('Compass Calibration'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            QiblaService.getCalibrationInstructions(),
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        Provider.of<PreferenceSettingsProvider>(context).isDarkTheme;

    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF091945) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Qibla Direction',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
            onPressed: _showCalibrationInstructions,
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
            onPressed: () => _qiblaProvider.refresh(),
          ),
        ],
      ),
      body: _buildBody(isDarkTheme),
    );
  }

  Widget _buildBody(bool isDarkTheme) {
    if (_qiblaProvider.isLoading) {
      return _buildLoadingState(isDarkTheme);
    }

    if (_qiblaProvider.error != null) {
      return _buildErrorState(isDarkTheme);
    }

    return _buildQiblaCompass(isDarkTheme);
  }

  Widget _buildLoadingState(bool isDarkTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding Qibla Direction...',
            style: TextStyle(
              fontSize: 18,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting your location and calculating direction to Mecca',
            style: TextStyle(
              fontSize: 14,
              color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDarkTheme ? Colors.red.shade300 : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to determine Qibla direction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.white : const Color(0xFF091945),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _qiblaProvider.error ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _qiblaProvider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCompass(bool isDarkTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Distance info
            _buildDistanceInfo(isDarkTheme),
            const SizedBox(height: 32),

            // Compass
            _buildCompass(isDarkTheme),
            const SizedBox(height: 32),

            // Direction info
            _buildDirectionInfo(isDarkTheme),
            const SizedBox(height: 24),

            // Calibration tip
            _buildCalibrationTip(isDarkTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceInfo(bool isDarkTheme) {
    final distance = _qiblaProvider.distanceToMecca;
    if (distance == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.place,
            color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Distance to Mecca: ${QiblaService.formatDistance(distance)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(bool isDarkTheme) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass background
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade100,
                  isDarkTheme
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade50,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Compass markings
          _buildCompassMarkings(isDarkTheme),

          // Qibla direction needle
          if (_qiblaProvider.relativeQiblaDirection != null)
            _buildQiblaNeedle(_qiblaProvider.relativeQiblaDirection!),

          // North indicator
          _buildNorthIndicator(isDarkTheme),

          // Center point
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkTheme ? Colors.white : const Color(0xFF091945),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassMarkings(bool isDarkTheme) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: CompassMarkingsPainter(isDarkTheme: isDarkTheme),
      ),
    );
  }

  Widget _buildQiblaNeedle(double angle) {
    return Transform.rotate(
      angle: (angle * math.pi / 180),
      child: Container(
        width: 4,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.green, Colors.transparent],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildNorthIndicator(bool isDarkTheme) {
    return Positioned(
      top: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionInfo(bool isDarkTheme) {
    final relativeDirection = _qiblaProvider.relativeQiblaDirection;
    if (relativeDirection == null) return const SizedBox.shrink();

    final isAligned = relativeDirection >= 350 || relativeDirection <= 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAligned
            ? Colors.green.withOpacity(0.1)
            : (isDarkTheme
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAligned
              ? Colors.green
              : (isDarkTheme
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAligned ? Icons.done_all : Icons.explore,
                color: isAligned
                    ? Colors.green
                    : (isDarkTheme ? Colors.white : const Color(0xFF091945)),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAligned ? 'Aligned with Qibla!' : 'Turn to align with Qibla',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isAligned
                      ? Colors.green
                      : (isDarkTheme ? Colors.white : const Color(0xFF091945)),
                ),
              ),
            ],
          ),
          if (!isAligned) ...[
            const SizedBox(height: 8),
            Text(
              'Turn ${relativeDirection > 180 ? 'left' : 'right'} ${relativeDirection > 180 ? 360 - relativeDirection : relativeDirection}°',
              style: TextStyle(
                fontSize: 14,
                color: isDarkTheme ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalibrationTip(bool isDarkTheme) {
    return GestureDetector(
      onTap: _showCalibrationInstructions,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Tap for compass calibration tips',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassMarkingsPainter extends CustomPainter {
  final bool isDarkTheme;

  CompassMarkingsPainter({required this.isDarkTheme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color =
          isDarkTheme ? Colors.white.withOpacity(0.3) : Colors.grey.shade400
      ..strokeWidth = 2;

    // Draw major markings (every 30 degrees)
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final startPoint = Offset(
        center.dx + (radius - 25) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 25) * math.sin(angle - math.pi / 2),
      );
      final endPoint = Offset(
        center.dx + (radius - 10) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 10) * math.sin(angle - math.pi / 2),
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }

    // Draw minor markings (every 10 degrees)
    paint.strokeWidth = 1;
    for (int i = 0; i < 36; i++) {
      if (i % 3 != 0) {
        // Skip major markings
        final angle = i * 10 * math.pi / 180;
        final startPoint = Offset(
          center.dx + (radius - 20) * math.cos(angle - math.pi / 2),
          center.dy + (radius - 20) * math.sin(angle - math.pi / 2),
        );
        final endPoint = Offset(
          center.dx + (radius - 10) * math.cos(angle - math.pi / 2),
          center.dy + (radius - 10) * math.sin(angle - math.pi / 2),
        );
        canvas.drawLine(startPoint, endPoint, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
