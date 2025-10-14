import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom refresh indicator with enhanced animations
class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _positionController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );


  }

  @override
  void dispose() {
    _positionController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _scaleController.forward();
    _rotationController.repeat();
    
    try {
      await widget.onRefresh();
    } finally {
      _rotationController.stop();
      _rotationController.reset();
      _scaleController.reverse();
      _positionController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: widget.displacement,
      edgeOffset: widget.edgeOffset,
      color: widget.color ?? theme.colorScheme.primary,
      backgroundColor: widget.backgroundColor ?? theme.colorScheme.surface,
      child: widget.child,
    );
  }
}

/// Enhanced pull-to-refresh with custom indicator
class EnhancedRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshText;
  final String? releaseText;
  final String? loadingText;
  final Color? indicatorColor;
  final Color? textColor;

  const EnhancedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshText = 'Pull to refresh',
    this.releaseText = 'Release to refresh',
    this.loadingText = 'Refreshing...',
    this.indicatorColor,
    this.textColor,
  });

  @override
  State<EnhancedRefreshIndicator> createState() => _EnhancedRefreshIndicatorState();
}

class _EnhancedRefreshIndicatorState extends State<EnhancedRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  RefreshState _refreshState = RefreshState.idle;
  double _dragOffset = 0.0;
  static const double _refreshTriggerPullDistance = 100.0;
  static const double _refreshIndicatorExtent = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.extentBefore == 0.0 && notification.dragDetails != null) {
        setState(() {
          _dragOffset = math.max(0.0, _dragOffset - notification.scrollDelta!);
          
          if (_dragOffset > _refreshTriggerPullDistance && _refreshState == RefreshState.idle) {
            _refreshState = RefreshState.canRefresh;
          } else if (_dragOffset <= _refreshTriggerPullDistance && _refreshState == RefreshState.canRefresh) {
            _refreshState = RefreshState.idle;
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_refreshState == RefreshState.canRefresh) {
        _triggerRefresh();
      } else {
        _resetRefresh();
      }
    }
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _refreshState = RefreshState.refreshing;
    });
    
    _controller.forward();
    
    try {
      await widget.onRefresh();
    } finally {
      _controller.reverse();
      _resetRefresh();
    }
  }

  void _resetRefresh() {
    setState(() {
      _refreshState = RefreshState.idle;
      _dragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(notification);
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_refreshState != RefreshState.idle)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final progress = _refreshState == RefreshState.refreshing 
                      ? _animation.value 
                      : math.min(1.0, _dragOffset / _refreshTriggerPullDistance);
                  
                  return Transform.translate(
                    offset: Offset(0, -_refreshIndicatorExtent + (_refreshIndicatorExtent * progress)),
                    child: Container(
                      height: _refreshIndicatorExtent,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildRefreshIndicator(theme, progress),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshIndicator(ThemeData theme, double progress) {
    String text;
    switch (_refreshState) {
      case RefreshState.idle:
        text = widget.refreshText ?? 'Pull to refresh';
        break;
      case RefreshState.canRefresh:
        text = widget.releaseText ?? 'Release to refresh';
        break;
      case RefreshState.refreshing:
        text = widget.loadingText ?? 'Refreshing...';
        break;
    }

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_refreshState == RefreshState.refreshing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.indicatorColor ?? theme.colorScheme.primary,
              ),
            )
          else
            Transform.rotate(
              angle: progress * math.pi,
              child: Icon(
                Icons.refresh,
                color: widget.indicatorColor ?? theme.colorScheme.primary,
                size: 20,
              ),
            ),
          const SizedBox(width: 12),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: widget.textColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Refresh states
enum RefreshState {
  idle,
  canRefresh,
  refreshing,
}

/// Bouncy scroll physics for enhanced feel
class BouncyScrollPhysics extends ScrollPhysics {
  const BouncyScrollPhysics({super.parent});

  @override
  BouncyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BouncyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 8000.0;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    
    return null;
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.5,
    stiffness: 100.0,
    damping: 0.8,
  );
}