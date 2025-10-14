import 'package:flutter/material.dart';
import 'package:odtrack_academia/shared/widgets/skeleton_screens.dart';

/// Enhanced loading widget with skeleton screen support
class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final LoadingType type;
  final Widget? skeletonWidget;

  const LoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
    this.type = LoadingType.spinner,
    this.skeletonWidget,
  });

  /// Factory constructor for dashboard loading
  const LoadingWidget.dashboard({
    super.key,
    this.message,
  }) : size = null,
       color = null,
       type = LoadingType.skeleton,
       skeletonWidget = const DashboardSkeleton();

  /// Factory constructor for staff inbox loading
  const LoadingWidget.staffInbox({
    super.key,
    this.message,
  }) : size = null,
       color = null,
       type = LoadingType.skeleton,
       skeletonWidget = const StaffInboxSkeleton();

  /// Factory constructor for analytics loading
  const LoadingWidget.analytics({
    super.key,
    this.message,
  }) : size = null,
       color = null,
       type = LoadingType.skeleton,
       skeletonWidget = const AnalyticsSkeleton();

  /// Factory constructor for list loading
  LoadingWidget.list({
    super.key,
    this.message,
    int itemCount = 6,
    bool showAvatar = true,
    bool showTrailing = true,
    int subtitleLines = 1,
  }) : size = null,
       color = null,
       type = LoadingType.skeleton,
       skeletonWidget = _ListSkeleton(
         itemCount: itemCount,
         showAvatar: showAvatar,
         showTrailing: showTrailing,
         subtitleLines: subtitleLines,
       );

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.skeleton:
        return skeletonWidget ?? const DashboardSkeleton();
      case LoadingType.spinner:
        return _buildSpinnerLoading(context);
    }
  }

  Widget _buildSpinnerLoading(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              color: color ?? theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading types for different scenarios
enum LoadingType {
  spinner,
  skeleton,
}

/// Helper widget for list skeleton
class _ListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showAvatar;
  final bool showTrailing;
  final int subtitleLines;

  const _ListSkeleton({
    required this.itemCount,
    required this.showAvatar,
    required this.showTrailing,
    required this.subtitleLines,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => ListItemSkeleton(
        showAvatar: showAvatar,
        showTrailing: showTrailing,
        subtitleLines: subtitleLines,
      ),
    );
  }
}