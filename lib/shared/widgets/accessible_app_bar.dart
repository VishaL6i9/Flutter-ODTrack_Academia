import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';
import 'package:odtrack_academia/core/accessibility/focus_manager.dart';
import 'package:odtrack_academia/shared/widgets/breadcrumb_widget.dart';

/// Accessible app bar with breadcrumbs and keyboard navigation
class AccessibleAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBreadcrumbs;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;

  const AccessibleAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBreadcrumbs = true,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize {
    const baseHeight = kToolbarHeight;
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    const breadcrumbHeight = 40.0;
    return Size.fromHeight(baseHeight + bottomHeight + (showBreadcrumbs ? breadcrumbHeight : 0));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService.instance;
    final focusManager = EnhancedFocusManager.instance;

    // Register focus nodes for keyboard navigation
    final titleFocusNode = FocusNode();
    focusManager.registerFocusNode('app_bar_title', titleFocusNode);

    return Semantics(
      container: true,
      label: 'App navigation bar',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Semantics(
              header: true,
              label: accessibilityService.getSemanticLabel(
                label: title,
                hint: 'Current page title',
              ),
              focusable: true,
              child: Focus(
                focusNode: titleFocusNode,
                child: Text(
                  title,
                  semanticsLabel: title,
                ),
              ),
            ),
            actions: actions?.map((action) => _wrapActionWithSemantics(action)).toList(),
            automaticallyImplyLeading: automaticallyImplyLeading,
            leading: leading != null ? _wrapLeadingWithSemantics(leading!) : null,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: elevation,
            centerTitle: centerTitle,
            bottom: bottom,
          ),
          if (showBreadcrumbs)
            Container(
              decoration: BoxDecoration(
                color: backgroundColor ?? theme.appBarTheme.backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: const CompactBreadcrumbWidget(),
            ),
        ],
      ),
    );
  }

  Widget _wrapActionWithSemantics(Widget action) {
    if (action is IconButton) {
      return Semantics(
        button: true,
        label: action.tooltip ?? 'Action button',
        hint: 'Double tap to activate',
        child: action,
      );
    }
    
    if (action is PopupMenuButton) {
      return Semantics(
        button: true,
        label: action.tooltip ?? 'Menu button',
        hint: 'Double tap to open menu',
        child: action,
      );
    }

    return Semantics(
      button: true,
      label: 'Action button',
      hint: 'Double tap to activate',
      child: action,
    );
  }

  Widget _wrapLeadingWithSemantics(Widget leading) {
    if (leading is IconButton) {
      return Semantics(
        button: true,
        label: leading.tooltip ?? 'Navigation button',
        hint: 'Double tap to navigate',
        child: leading,
      );
    }

    return Semantics(
      button: true,
      label: 'Navigation button',
      hint: 'Double tap to navigate',
      child: leading,
    );
  }
}

/// Accessible sliver app bar for scrollable content
class AccessibleSliverAppBar extends ConsumerWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBreadcrumbs;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double? expandedHeight;
  final Widget? flexibleSpace;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;

  const AccessibleSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBreadcrumbs = true,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight,
    this.flexibleSpace,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService.instance;

    return SliverAppBar(
      title: Semantics(
        header: true,
        label: accessibilityService.getSemanticLabel(
          label: title,
          hint: 'Current page title',
        ),
        child: Text(
          title,
          semanticsLabel: title,
        ),
      ),
      actions: actions?.map((action) => _wrapActionWithSemantics(action)).toList(),
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace,
      leading: leading != null ? _wrapLeadingWithSemantics(leading!) : null,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      bottom: showBreadcrumbs ? PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.appBarTheme.backgroundColor,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: const CompactBreadcrumbWidget(),
        ),
      ) : null,
    );
  }

  Widget _wrapActionWithSemantics(Widget action) {
    if (action is IconButton) {
      return Semantics(
        button: true,
        label: action.tooltip ?? 'Action button',
        hint: 'Double tap to activate',
        child: action,
      );
    }
    
    if (action is PopupMenuButton) {
      return Semantics(
        button: true,
        label: action.tooltip ?? 'Menu button',
        hint: 'Double tap to open menu',
        child: action,
      );
    }

    return Semantics(
      button: true,
      label: 'Action button',
      hint: 'Double tap to activate',
      child: action,
    );
  }

  Widget _wrapLeadingWithSemantics(Widget leading) {
    if (leading is IconButton) {
      return Semantics(
        button: true,
        label: leading.tooltip ?? 'Navigation button',
        hint: 'Double tap to navigate',
        child: leading,
      );
    }

    return Semantics(
      button: true,
      label: 'Navigation button',
      hint: 'Double tap to navigate',
      child: leading,
    );
  }
}