import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odtrack_academia/core/navigation/navigation_service.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';

/// Provider for navigation service
final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService.instance;
});

/// Breadcrumb navigation widget with accessibility support
class BreadcrumbWidget extends ConsumerWidget {
  final bool showIcons;
  final TextStyle? textStyle;
  final Color? separatorColor;
  final double? separatorSize;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const BreadcrumbWidget({
    super.key,
    this.showIcons = true,
    this.textStyle,
    this.separatorColor,
    this.separatorSize,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.watch(navigationServiceProvider);
    final breadcrumbs = navigationService.breadcrumbs;
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService.instance;

    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveTextStyle = textStyle ?? theme.textTheme.bodyMedium;
    final effectiveSeparatorColor = separatorColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final effectiveSeparatorSize = separatorSize ?? 16.0;

    Widget buildBreadcrumbItem(BreadcrumbItem item, int index, bool isLast) {
      final isClickable = !isLast && item.route.isNotEmpty;
      
      Widget content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcons && item.icon != null) ...[
            Icon(
              item.icon,
              size: effectiveTextStyle?.fontSize ?? 14,
              color: isLast 
                  ? theme.colorScheme.onSurface 
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              item.label,
              style: effectiveTextStyle?.copyWith(
                color: isLast 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.primary,
                fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

      if (isClickable) {
        return Semantics(
          button: true,
          label: accessibilityService.getSemanticLabel(
            label: 'Navigate to ${item.label}',
            hint: 'Breadcrumb navigation item ${index + 1} of ${breadcrumbs.length}',
          ),
          child: InkWell(
            onTap: () {
              // Navigate to the breadcrumb route
              navigationService.removeBreadcrumbsAfter(item.route);
              if (item.queryParameters != null) {
                context.go(item.route, extra: item.queryParameters);
              } else {
                context.go(item.route);
              }
              
              // Announce navigation to screen reader
              accessibilityService.announceToScreenReader(
                'Navigated to ${item.label}'
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: content,
            ),
          ),
        );
      }

      return Semantics(
        label: accessibilityService.getSemanticLabel(
          label: 'Current page: ${item.label}',
          hint: 'Breadcrumb item ${index + 1} of ${breadcrumbs.length}',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }

    Widget buildSeparator() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(
          Icons.chevron_right,
          size: effectiveSeparatorSize,
          color: effectiveSeparatorColor,
          semanticLabel: 'breadcrumb separator',
        ),
      );
    }

    List<Widget> breadcrumbWidgets = [];
    for (int i = 0; i < breadcrumbs.length; i++) {
      final item = breadcrumbs[i];
      final isLast = i == breadcrumbs.length - 1;
      
      breadcrumbWidgets.add(buildBreadcrumbItem(item, i, isLast));
      
      if (!isLast) {
        breadcrumbWidgets.add(buildSeparator());
      }
    }

    Widget breadcrumbContent = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: breadcrumbWidgets,
    );

    if (scrollable && breadcrumbs.length > 3) {
      breadcrumbContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: breadcrumbWidgets,
        ),
      );
    }

    return Semantics(
      label: 'Navigation breadcrumbs',
      hint: 'Shows your current location in the app',
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: breadcrumbContent,
      ),
    );
  }
}

/// Compact breadcrumb widget for app bars
class CompactBreadcrumbWidget extends ConsumerWidget {
  final int maxItems;
  final bool showBackButton;

  const CompactBreadcrumbWidget({
    super.key,
    this.maxItems = 2,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.watch(navigationServiceProvider);
    final breadcrumbs = navigationService.breadcrumbs;
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService.instance;

    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only the last few breadcrumbs (currently not used but kept for future enhancement)

    return Row(
      children: [
        if (showBackButton && navigationService.canNavigateBack) ...[
          Semantics(
            button: true,
            label: 'Navigate back',
            hint: 'Go back to previous page',
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                navigationService.navigateBack(context);
                accessibilityService.announceToScreenReader('Navigated back');
              },
              tooltip: 'Back',
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: BreadcrumbWidget(
            showIcons: false,
            textStyle: theme.textTheme.titleMedium,
            scrollable: true,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}