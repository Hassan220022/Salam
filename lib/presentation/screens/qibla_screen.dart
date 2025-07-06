import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../services/qibla_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  late AnimationController _alignmentController;

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
    _alignmentController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _initializeQibla();
  }

  @override
  void dispose() {
    _compassController.dispose();
    _pulseController.dispose();
    _alignmentController.dispose();
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
        title: const Text('Qibla Direction'),
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

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 600),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Accuracy and Status Bar
            _buildStatusBar(),
            
            // Main Compass Area
            Expanded(
              child: _buildQiblaCompass(),
            ),
            
            // Bottom Information Panel
            _buildBottomPanel(),
          ],
        ),
      ),
    );
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

  Widget _buildStatusBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Row(
        children: [
          // Compass Accuracy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      size: 16,
                      color: _qiblaProvider.accuracyColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Accuracy',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  _qiblaProvider.accuracyDescription,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _qiblaProvider.accuracyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Calibration Status
          if (_qiblaProvider.needsCalibration)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Calibrate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Distance to Mecca
          if (_qiblaProvider.distanceToMecca != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Distance',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    QiblaService.formatDistance(_qiblaProvider.distanceToMecca!),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
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

  Widget _buildQiblaCompass() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main Compass
            _buildCompass(),
            const SizedBox(height: 24),
            
            // Direction info
            _buildDirectionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass background with gradient
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // Compass markings and cardinal directions
          _buildCompassMarkings(),

          // Qibla direction needle
          if (_qiblaProvider.relativeQiblaDirection != null)
            _buildQiblaNeedle(_qiblaProvider.relativeQiblaDirection!),

          // Cardinal direction indicators
          _buildCardinalDirections(),

          // Center point with pulse animation when aligned
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: _qiblaProvider.isAligned ? 
                  16 + (4 * _pulseController.value) : 12,
                height: _qiblaProvider.isAligned ? 
                  16 + (4 * _pulseController.value) : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _qiblaProvider.isAligned 
                    ? Colors.green 
                    : theme.colorScheme.onSurface,
                  boxShadow: _qiblaProvider.isAligned ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompassMarkings() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 320,
      height: 320,
      child: CustomPaint(
        painter: EnhancedCompassMarkingsPainter(theme: theme),
      ),
    );
  }

  Widget _buildQiblaNeedle(double angle) {
    return AnimatedBuilder(
      animation: _alignmentController,
      builder: (context, child) {
        return Transform.rotate(
          angle: (angle * math.pi / 180),
          child: Container(
            width: 6,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _qiblaProvider.isAligned 
                  ? [Colors.green.shade400, Colors.green, Colors.green.shade700, Colors.transparent]
                  : [Colors.green.shade300, Colors.green, Colors.green.shade600, Colors.transparent],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.6),
                  blurRadius: _qiblaProvider.isAligned ? 8 : 4,
                  spreadRadius: _qiblaProvider.isAligned ? 2 : 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardinalDirections() {
    final theme = Theme.of(context);
    final directions = ['N', 'E', 'S', 'W'];
    final colors = [
      Colors.red,
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];
    
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        children: List.generate(4, (index) {
          final angle = index * 90.0;
          final angleRad = (angle - 90) * math.pi / 180;
          final radius = 140.0;
          final x = 160 + radius * math.cos(angleRad) - 16;
          final y = 160 + radius * math.sin(angleRad) - 16;
          
          return Positioned(
            left: x,
            top: y,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[index],
                boxShadow: [
                  BoxShadow(
                    color: colors[index].withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  directions[index],
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDirectionInfo() {
    final relativeDirection = _qiblaProvider.relativeQiblaDirection;
    if (relativeDirection == null) return const SizedBox.shrink();

    final isAligned = _qiblaProvider.isAligned;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isAligned ? [
            Colors.green.withValues(alpha: 0.2),
            Colors.green.withValues(alpha: 0.1),
          ] : [
            theme.colorScheme.surfaceContainer,
            theme.colorScheme.surfaceContainerHigh,
          ],
        ),
        border: Border.all(
          color: isAligned ? Colors.green : theme.dividerColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAligned ? Colors.green : theme.colorScheme.shadow)
              .withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedRotation(
                turns: isAligned ? 0.0 : 0.25,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isAligned ? Icons.check_circle : Icons.explore,
                  color: isAligned ? Colors.green : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isAligned ? 'Perfectly Aligned with Qibla!' : 'Rotate to align with Qibla',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAligned ? Colors.green : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (!isAligned) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Turn ${relativeDirection > 180 ? 'left' : 'right'} ${(relativeDirection > 180 ? 360 - relativeDirection : relativeDirection).toStringAsFixed(0)}°',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Calibration tip
          Expanded(
            child: GestureDetector(
              onTap: _showCalibrationInstructions,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Calibration Tips',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Refresh button
          Material(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _qiblaProvider.refresh(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: theme.colorScheme.onPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Refresh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedCompassMarkingsPainter extends CustomPainter {
  final ThemeData theme;

  EnhancedCompassMarkingsPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Major markings (every 30 degrees)
    final majorPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final startPoint = Offset(
        center.dx + (radius - 30) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 30) * math.sin(angle - math.pi / 2),
      );
      final endPoint = Offset(
        center.dx + (radius - 10) * math.cos(angle - math.pi / 2),
        center.dy + (radius - 10) * math.sin(angle - math.pi / 2),
      );
      canvas.drawLine(startPoint, endPoint, majorPaint);
    }

    // Minor markings (every 10 degrees)
    final minorPaint = Paint()
      ..color = theme.colorScheme.onSurface.withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      if (i % 3 != 0) {
        final angle = i * 10 * math.pi / 180;
        final startPoint = Offset(
          center.dx + (radius - 20) * math.cos(angle - math.pi / 2),
          center.dy + (radius - 20) * math.sin(angle - math.pi / 2),
        );
        final endPoint = Offset(
          center.dx + (radius - 10) * math.cos(angle - math.pi / 2),
          center.dy + (radius - 10) * math.sin(angle - math.pi / 2),
        );
        canvas.drawLine(startPoint, endPoint, minorPaint);
      }
    }

    // Degree numbers (every 30 degrees)
    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < 12; i++) {
      final angle = i * 30;
      final angleRad = i * 30 * math.pi / 180;
      final textPosition = Offset(
        center.dx + (radius - 45) * math.cos(angleRad - math.pi / 2),
        center.dy + (radius - 45) * math.sin(angleRad - math.pi / 2),
      );

      final textPainter = TextPainter(
        text: TextSpan(text: '${angle}°', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textPosition.dx - textPainter.width / 2,
          textPosition.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
