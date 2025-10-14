import 'package:flutter/material.dart';

/// Custom page route with enhanced transitions
class EnhancedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;

  EnhancedPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slideFromRight,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOut,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              context,
              animation,
              secondaryAnimation,
              child,
              transitionType,
              curve,
            );
          },
        );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    PageTransitionType type,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (type) {
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case PageTransitionType.slideAndFade:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case PageTransitionType.scaleAndRotate:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: RotationTransition(
            turns: Tween<double>(
              begin: -0.1,
              end: 0.0,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );

      case PageTransitionType.elasticIn:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: child,
        );

      case PageTransitionType.bounceIn:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.bounceOut,
          )),
          child: child,
        );
    }
  }
}

/// Page transition types
enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  rotation,
  slideAndFade,
  scaleAndRotate,
  elasticIn,
  bounceIn,
}

/// Hero page route with custom transitions
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final String heroTag;
  final Duration duration;

  HeroPageRoute({
    required this.child,
    required this.heroTag,
    this.duration = const Duration(milliseconds: 400),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Shared axis transition (Material Design 3)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final SharedAxisTransitionType transitionType;
  final Duration duration;

  SharedAxisPageRoute({
    required this.child,
    this.transitionType = SharedAxisTransitionType.horizontal,
    this.duration = const Duration(milliseconds: 300),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildSharedAxisTransition(
              animation,
              secondaryAnimation,
              child,
              transitionType,
            );
          },
        );

  static Widget _buildSharedAxisTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    SharedAxisTransitionType type,
  ) {
    switch (type) {
      case SharedAxisTransitionType.horizontal:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
          )),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            )),
            child: child,
          ),
        );

      case SharedAxisTransitionType.vertical:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Cubic(0.2, 0.0, 0.0, 1.0),
          )),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.0, -0.3),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            )),
            child: child,
          ),
        );

      case SharedAxisTransitionType.scaled:
        return FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.75, curve: Cubic(0.2, 0.0, 0.0, 1.0)),
          )),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.2, 0.0, 0.0, 1.0),
            )),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 1.0,
                end: 0.0,
              ).animate(CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0.25, 1.0, curve: Cubic(0.2, 0.0, 0.0, 1.0)),
              )),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 1.0,
                  end: 1.1,
                ).animate(CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: const Cubic(0.2, 0.0, 0.0, 1.0),
                )),
                child: child,
              ),
            ),
          ),
        );
    }
  }
}

/// Shared axis transition types
enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

/// Fade through transition (Material Design 3)
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  FadeThroughPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
              )),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 1.0,
                  end: 0.0,
                ).animate(CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
                )),
                child: child,
              ),
            );
          },
        );
}

/// Container transform transition (Material Design 3)
class ContainerTransformPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;
  final Color? containerColor;

  ContainerTransformPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.containerColor,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 1.0, curve: Cubic(0.2, 0.0, 0.0, 1.0)),
              )),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Cubic(0.2, 0.0, 0.0, 1.0)),
                )),
                child: child,
              ),
            );
          },
        );
}