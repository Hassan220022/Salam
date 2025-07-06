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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Qibla Direction',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showCalibrationInstructions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _qiblaProvider.refresh(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_qiblaProvider.isLoading) {
      return _buildLoadingState();
    }

    if (_qiblaProvider.error != null) {
      return _buildErrorState();
    }

    return _buildQiblaCompass();
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Finding Qibla Direction...',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Getting your location and calculating direction to Mecca',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to determine Qibla direction',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _qiblaProvider.error ?? 'Unknown error occurred',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _qiblaProvider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onError,
                backgroundColor: theme.colorScheme.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQiblaCompass() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Distance info
            _buildDistanceInfo(),
            const SizedBox(height: 32),

            // Compass
            _buildCompass(),
            const SizedBox(height: 32),

            // Direction info
            _buildDirectionInfo(),
            const SizedBox(height: 24),

            // Calibration tip
            _buildCalibrationTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceInfo() {
    final distance = _qiblaProvider.distanceToMecca;
    if (distance == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place,
              color: theme.colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Distance to Mecca: ${QiblaService.formatDistance(distance)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    final theme = Theme.of(context);
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
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceVariant,
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
          _buildCompassMarkings(),

          // Qibla direction needle
          if (_qiblaProvider.relativeQiblaDirection != null)
            _buildQiblaNeedle(_qiblaProvider.relativeQiblaDirection!),

          // North indicator
          _buildNorthIndicator(),

          // Center point
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassMarkings() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(
        painter: CompassMarkingsPainter(theme: theme),
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

  Widget _buildNorthIndicator() {
    final theme = Theme.of(context);
    return Positioned(
      top: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'N',
          style: theme.primaryTextTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionInfo() {
    final relativeDirection = _qiblaProvider.relativeQiblaDirection;
    if (relativeDirection == null) return const SizedBox.shrink();

    final isAligned = relativeDirection >= 350 || relativeDirection <= 10;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      color: isAligned ? Colors.green.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAligned ? Colors.green : theme.dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAligned ? Icons.done_all : Icons.explore,
                  color: isAligned ? Colors.green : theme.colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isAligned ? 'Aligned with Qibla!' : 'Turn to align with Qibla',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isAligned ? Colors.green : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (!isAligned) ...[
              const SizedBox(height: 8),
              Text(
                'Turn ${relativeDirection > 180 ? 'left' : 'right'} ${relativeDirection > 180 ? 360 - relativeDirection : relativeDirection}°',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationTip() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _showCalibrationInstructions,
      child: Card(
        elevation: 0,
        color: Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Tap for compass calibration tips',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompassMarkingsPainter extends CustomPainter {
  final ThemeData theme;

  CompassMarkingsPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = theme.colorScheme.onSurface.withOpacity(0.3)
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
