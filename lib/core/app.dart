import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';
import 'package:odtrack_academia/core/router/app_router.dart';
import 'package:odtrack_academia/core/constants/app_constants.dart';
import 'package:odtrack_academia/core/accessibility/focus_manager.dart';
import 'package:odtrack_academia/providers/permissions_provider.dart';

final _logger = Logger('ODTrackApp');

class ODTrackApp extends ConsumerStatefulWidget {
  const ODTrackApp({super.key});

  @override
  ConsumerState<ODTrackApp> createState() => _ODTrackAppState();
}

class _ODTrackAppState extends ConsumerState<ODTrackApp> {
  @override
  void initState() {
    super.initState();
    _logger.info('ODTrackApp initialized');
    // Check permissions on app launch
    ref.read(permissionsProvider.notifier).refreshPermissions();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('Building ODTrackApp');
    
    final router = ref.watch(appRouterProvider);
    _logger.info('Router obtained from provider');
    
    final focusManager = EnhancedFocusManager.instance;
    
    return Shortcuts(
      shortcuts: focusManager.getNavigationShortcuts(),
      child: Actions(
        actions: focusManager.getNavigationActions(context),
        child: FocusTraversalGroup(
          policy: AccessibleFocusTraversalPolicy(),
          child: MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                // Ensure text scaling is accessible
                data: MediaQuery.of(context).copyWith(
                  textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 2.0),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
    );
  }
}
