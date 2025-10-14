import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base skeleton loading widget with shimmer effect
class SkeletonLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Skeleton for circular avatar
class SkeletonAvatar extends StatelessWidget {
  final double radius;

  const SkeletonAvatar({
    super.key,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      width: radius * 2,
      height: radius * 2,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Skeleton for text lines
class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final int lines;
  final double spacing;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 16,
    this.lines = 1,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (lines == 1) {
      return SkeletonLoading(
        width: width,
        height: height,
        borderRadius: BorderRadius.circular(height / 2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        final lineWidth = isLast && width != null 
            ? width! * 0.7  // Make last line shorter
            : width;
        
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: SkeletonLoading(
            width: lineWidth,
            height: height,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        );
      }),
    );
  }
}

/// Skeleton for buttons
class SkeletonButton extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonButton({
    super.key,
    this.width,
    this.height = 40,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }
}

/// Skeleton for cards
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Widget? child;

  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}