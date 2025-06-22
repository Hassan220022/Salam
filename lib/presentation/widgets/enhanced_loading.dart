import 'package:flutter/material.dart';

class EnhancedLoading extends StatefulWidget {
  final String? message;
  final LoadingStyle style;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double size;

  const EnhancedLoading({
    super.key,
    this.message,
    this.style = LoadingStyle.quranStyle,
    this.primaryColor,
    this.secondaryColor,
    this.size = 60.0,
  });

  @override
  State<EnhancedLoading> createState() => _EnhancedLoadingState();
}

enum LoadingStyle {
  quranStyle,
  prayerStyle,
  downloadStyle,
  rippleStyle,
  pulseStyle,
}

class _EnhancedLoadingState extends State<EnhancedLoading>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late Animation<double> _primaryAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _primaryController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _primaryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _primaryController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildLoadingWidget(),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 16,
              color: widget.primaryColor ?? const Color(0xFF667eea),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget() {
    switch (widget.style) {
      case LoadingStyle.quranStyle:
        return _buildQuranStyleLoading();
      case LoadingStyle.prayerStyle:
        return _buildPrayerStyleLoading();
      case LoadingStyle.downloadStyle:
        return _buildDownloadStyleLoading();
      case LoadingStyle.rippleStyle:
        return _buildRippleStyleLoading();
      case LoadingStyle.pulseStyle:
        return _buildPulseStyleLoading();
    }
  }

  Widget _buildQuranStyleLoading() {
    return AnimatedBuilder(
      animation: _primaryAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Transform.rotate(
              angle: _primaryAnimation.value * 2 * 3.14159,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      widget.primaryColor ?? const Color(0xFF667eea),
                      widget.secondaryColor ?? const Color(0xFF764ba2),
                    ],
                    stops: [0.3, 1.0],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
            ),
            // Inner Quran symbol
            Container(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor ?? const Color(0xFF667eea),
                    widget.secondaryColor ?? const Color(0xFF764ba2),
                  ],
                ),
              ),
              child: const Icon(
                Icons.menu_book,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrayerStyleLoading() {
    return AnimatedBuilder(
      animation: _primaryAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating crescent
            Transform.rotate(
              angle: _primaryAnimation.value * 2 * 3.14159,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.primaryColor ?? const Color(0xFF2196F3),
                    width: 3,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (widget.primaryColor ?? const Color(0xFF2196F3))
                        .withOpacity(0.2),
                  ),
                ),
              ),
            ),
            // Kaaba icon
            Icon(
              Icons.home,
              size: widget.size * 0.4,
              color: widget.primaryColor ?? const Color(0xFF2196F3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadStyleLoading() {
    return AnimatedBuilder(
      animation: _primaryAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Progress circle
            CircularProgressIndicator(
              value: _primaryAnimation.value,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.primaryColor ?? const Color(0xFFFF9800),
              ),
              backgroundColor: (widget.primaryColor ?? const Color(0xFFFF9800))
                  .withOpacity(0.2),
            ),
            // Download icon
            Icon(
              Icons.cloud_download,
              size: widget.size * 0.4,
              color: widget.primaryColor ?? const Color(0xFFFF9800),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRippleStyleLoading() {
    return AnimatedBuilder(
      animation: _primaryAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effect
            for (int i = 0; i < 3; i++)
              Transform.scale(
                scale: 0.5 + (i * 0.3) + _primaryAnimation.value * 0.7,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (widget.primaryColor ?? const Color(0xFF4CAF50))
                          .withOpacity(
                              0.8 - (i * 0.2) - _primaryAnimation.value * 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            // Center dot
            Container(
              width: widget.size * 0.2,
              height: widget.size * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primaryColor ?? const Color(0xFF4CAF50),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPulseStyleLoading() {
    return AnimatedBuilder(
      animation: _primaryAnimation,
      builder: (context, child) {
        final pulseValue =
            (1.0 + 0.3 * (1.0 + _primaryAnimation.value)).clamp(0.0, 1.5);

        return Transform.scale(
          scale: pulseValue,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.primaryColor ?? const Color(0xFF9C27B0),
                  (widget.secondaryColor ?? const Color(0xFF673AB7))
                      .withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.primaryColor ?? const Color(0xFF9C27B0))
                      .withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: widget.size * 0.4,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _primaryController.dispose();
    super.dispose();
  }
}

// Shimmer loading for lists
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        widget.baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final LoadingStyle style;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.style = LoadingStyle.quranStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: EnhancedLoading(
                  message: message,
                  style: style,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
