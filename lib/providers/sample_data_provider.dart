import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odtrack_academia/services/sample_data_service.dart';

/// Provider for the sample data service
final sampleDataServiceProvider = Provider<SampleDataService>((ref) {
  return SampleDataService();
});

/// State for sample data initialization
class SampleDataState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;

  const SampleDataState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
  });

  SampleDataState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
  }) {
    return SampleDataState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing sample data state
class SampleDataNotifier extends StateNotifier<SampleDataState> {
  final SampleDataService _sampleDataService;

  SampleDataNotifier(this._sampleDataService) : super(const SampleDataState());

  /// Initialize sample data if not already present
  Future<void> initializeSampleData() async {
    if (state.isInitialized || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if sample data already exists
      final hasData = await _sampleDataService.hasSampleData();
      
      if (!hasData) {
        // Initialize sample data
        await _sampleDataService.initializeSampleData();
      }

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize sample data: $e',
      );
    }
  }

  /// Clear all sample data
  Future<void> clearSampleData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _sampleDataService.clearSampleData();
      state = state.copyWith(
        isInitialized: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to clear sample data: $e',
      );
    }
  }

  /// Reinitialize sample data (clear and recreate)
  Future<void> reinitializeSampleData() async {
    await clearSampleData();
    await initializeSampleData();
  }
}

/// Provider for the sample data notifier
final sampleDataProvider = StateNotifierProvider<SampleDataNotifier, SampleDataState>((ref) {
  final sampleDataService = ref.watch(sampleDataServiceProvider);
  return SampleDataNotifier(sampleDataService);
});

/// Convenience providers
final sampleDataInitializedProvider = Provider<bool>((ref) {
  return ref.watch(sampleDataProvider).isInitialized;
});

final sampleDataLoadingProvider = Provider<bool>((ref) {
  return ref.watch(sampleDataProvider).isLoading;
});

final sampleDataErrorProvider = Provider<String?>((ref) {
  return ref.watch(sampleDataProvider).error;
});