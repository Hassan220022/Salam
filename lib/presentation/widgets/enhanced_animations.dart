import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/utils/app_theme.dart';

// Animated Card with enhanced entrance animations
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool reduceAnimations;
  final VoidCallback? onTap;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppTheme.mediumAnimation,
    this.reduceAnimations = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.reduceAnimations
          ? const Duration(milliseconds: 100)
          : widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.onTap != null
                  ? GestureDetector(
                      onTap: widget.onTap,
                      child: widget.child,
                    )
                  : widget.child,
            ),
          ),
        );
      },
    );
  }
}

// Bouncy list item animation
class BouncyListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final bool reduceAnimations;

  const BouncyListItem({
    Key? key,
    required this.child,
    required this.index,
    this.reduceAnimations = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reduceAnimations) {
      return child;
    }

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: AppTheme.mediumAnimation,
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }
}

// Pulse animation for buttons
class PulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final double scaleFactor;

  const PulseButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.scaleFactor = 0.95,
  }) : super(key: key);

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// Loading animation with Islamic pattern
class IslamicLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const IslamicLoadingAnimation({
    Key? key,
    this.size = 50.0,
    this.color,
  }) : super(key: key);

  @override
  State<IslamicLoadingAnimation> createState() =>
      _IslamicLoadingAnimationState();
}

class _IslamicLoadingAnimationState extends State<IslamicLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159,
            child: Transform.scale(
              scale: 0.8 + (_pulseController.value * 0.2),
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: IslamicPatternPainter(color: color),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for Islamic geometric pattern
class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw outer circle
    canvas.drawCircle(center, radius, paint);

    // Draw inner star pattern
    final starPath = Path();
    final angleStep = 2 * 3.14159 / 8; // 8-pointed star

    for (int i = 0; i < 8; i++) {
      final angle = i * angleStep;
      final x =
          center.dx + (radius * 0.7) * (i % 2 == 0 ? 1 : 0.5) * cos(angle);
      final y =
          center.dy + (radius * 0.7) * (i % 2 == 0 ? 1 : 0.5) * sin(angle);

      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }

    starPath.close();
    canvas.drawPath(starPath, paint);

    // Draw center circle
    canvas.drawCircle(center, radius * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Shimmer effect for loading states
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ShimmerWidget({
    Key? key,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.repeat();
    } else if (!widget.enabled && oldWidget.enabled) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _controller.value * 2, 0.0),
              end: Alignment(1.0 + _controller.value * 2, 0.0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Floating Action Button with enhanced animation
class EnhancedFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final bool mini;

  const EnhancedFAB({
    Key? key,
    this.onPressed,
    required this.child,
    this.tooltip,
    this.mini = false,
  }) : super(key: key);

  @override
  State<EnhancedFAB> createState() => _EnhancedFABState();
}

class _EnhancedFABState extends State<EnhancedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 0.1,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              tooltip: widget.tooltip,
              mini: widget.mini,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
