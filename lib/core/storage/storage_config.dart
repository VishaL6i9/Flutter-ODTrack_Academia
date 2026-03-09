import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odtrack_academia/models/sync_models.dart';
import 'package:odtrack_academia/models/analytics_models.dart';
import 'package:odtrack_academia/models/export_models.dart';
import 'package:odtrack_academia/models/bulk_operation_models.dart';
import 'package:odtrack_academia/models/performance_models.dart';
import 'package:odtrack_academia/models/staff_member.dart';
import 'package:odtrack_academia/models/staff_workload_models.dart';
import 'package:odtrack_academia/models/od_request.dart';
import 'package:odtrack_academia/models/user.dart';

/// Enhanced storage configuration for M5 features
class EnhancedStorageConfig {
  // Box names for M5 features
  static const String syncQueueBox = 'sync_queue_box';
  static const String analyticsBox = 'analytics_box';
  static const String exportHistoryBox = 'export_history_box';
  static const String calendarEventsBox = 'calendar_events_box';
  static const String bulkOperationsBox = 'bulk_operations_box';
  static const String performanceMetricsBox = 'performance_metrics_box';
  static const String cacheMetadataBox = 'cache_metadata_box';
  
  static const _secureStorage = FlutterSecureStorage();
  static const String _encryptionKeyString = 'hive_encryption_key_v1';
  static List<int>? _encryptionKey;
  
  /// Initialize enhanced storage with new adapters and boxes
  static Future<void> initialize() async {
    // Generate or fetch the encryption cipher key first
    await _initializeEncryption();
    
    // Register type adapters for M5 models
    _registerTypeAdapters();
    
    // Open all required boxes securely
    await _openBoxes();
  }
  
  static Future<void> _initializeEncryption() async {
    final containsEncryptionKey = await _secureStorage.containsKey(key: _encryptionKeyString);
    if (!containsEncryptionKey) {
      // Securely generate a new cryptographically random 32 byte base64 encoded sequence
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyString,
        value: base64UrlEncode(key),
      );
    }
    final encodedKey = await _secureStorage.read(key: _encryptionKeyString);
    if (encodedKey != null) {
      _encryptionKey = base64Url.decode(encodedKey);
    }
  }
  
  /// Register Hive type adapters for M5 models
  static void _registerTypeAdapters() {
    // Register User adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }

    // Register ODRequest adapter
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ODRequestAdapter());
    }
    
    // Register StaffMember adapter
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StaffMemberAdapter());
    }

    // Register workload models
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TimeSlotAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(PeriodAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SubjectAllocationAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(ClassAssignmentAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(ClassAllocationAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(WorkloadAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(WorkloadAnalyticsAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(StaffWorkloadDataAdapter());
    }

    // Register adapters for sync models - only register if not already registered
    if (!Hive.isAdapterRegistered(102)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(201)) {
      Hive.registerAdapter(SyncResultAdapter());
    }
    if (!Hive.isAdapterRegistered(202)) {
      Hive.registerAdapter(SyncConflictAdapter());
    }
    if (!Hive.isAdapterRegistered(203)) {
      Hive.registerAdapter(ConflictResolutionAdapter());
    }
    if (!Hive.isAdapterRegistered(214)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(215)) {
      Hive.registerAdapter(CacheMetadataAdapter());
    }
    if (!Hive.isAdapterRegistered(216)) {
      Hive.registerAdapter(SyncStatisticsAdapter());
    }
    
    // Register enum adapters for other models
    if (!Hive.isAdapterRegistered(103)) {
      Hive.registerAdapter(ExportFormatAdapter());
    }
    if (!Hive.isAdapterRegistered(104)) {
      Hive.registerAdapter(BulkOperationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(105)) {
      Hive.registerAdapter(PerformanceAlertTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(106)) {
      Hive.registerAdapter(AnalyticsTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(107)) {
      Hive.registerAdapter(ChartTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(108)) {
      Hive.registerAdapter(TrendDirectionAdapter());
    }

    // Register workload enum adapters
    if (!Hive.isAdapterRegistered(109)) {
      Hive.registerAdapter(ActivityTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(110)) {
      Hive.registerAdapter(GradeAdapter());
    }
    if (!Hive.isAdapterRegistered(111)) {
      Hive.registerAdapter(PeriodTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(112)) {
      Hive.registerAdapter(ClassTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(113)) {
      Hive.registerAdapter(SubjectTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(114)) {
      Hive.registerAdapter(WorkloadTrendAdapter());
    }
  }
  
  /// Open all required Hive boxes
  static Future<void> _openBoxes() async {
    final cipher = _encryptionKey != null ? HiveAesCipher(_encryptionKey!) : null;
    
    // Safely attempt to open a box. If corrupted or missing encryption parity, 
    // it zeroes the box preventing complete startup failure gracefully.
    Future<Box<T>> openBoxSafely<T>(String boxName) async {
      try {
        return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      } catch (e) {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
      }
    }

    Future<LazyBox<T>> openLazyBoxSafely<T>(String boxName) async {
      try {
        return await Hive.openLazyBox<T>(boxName, encryptionCipher: cipher);
      } catch (e) {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openLazyBox<T>(boxName, encryptionCipher: cipher);
      }
    }

    await Future.wait([
      openLazyBoxSafely<SyncQueueItem>(syncQueueBox),
      openLazyBoxSafely<Map<String, dynamic>>(analyticsBox),
      openLazyBoxSafely<Map<String, dynamic>>(exportHistoryBox),
      openLazyBoxSafely<Map<String, dynamic>>(calendarEventsBox),
      openLazyBoxSafely<Map<String, dynamic>>(bulkOperationsBox),
      openLazyBoxSafely<Map<String, dynamic>>(performanceMetricsBox),
      openBoxSafely<CacheMetadata>(cacheMetadataBox),
    ]);
  }
  
  /// Get a specific box by name
  static Box<T> getBox<T>(String boxName) {
    return Hive.box<T>(boxName);
  }
  
  /// Get a specific lazy box by name
  static LazyBox<T> getLazyBox<T>(String boxName) {
    return Hive.lazyBox<T>(boxName);
  }
  
  /// Close all boxes (for cleanup)
  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }
  
  /// Clear all M5 feature data (for reset/cleanup)
  static Future<void> clearAllM5Data() async {
    final boxes = [
      syncQueueBox,
      analyticsBox,
      exportHistoryBox,
      calendarEventsBox,
      bulkOperationsBox,
      performanceMetricsBox,
      cacheMetadataBox,
    ];
    
    for (final boxName in boxes) {
      final box = Hive.box<dynamic>(boxName);
      await box.clear();
    }
  }
}

// Type adapter classes for enums (these are manually created)
// The complex model adapters are generated by hive_generator in sync_models.g.dart

class ExportFormatAdapter extends TypeAdapter<ExportFormat> {
  @override
  final int typeId = 103;

  @override
  ExportFormat read(BinaryReader reader) {
    return ExportFormat.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ExportFormat obj) {
    writer.writeByte(obj.index);
  }
}

class BulkOperationTypeAdapter extends TypeAdapter<BulkOperationType> {
  @override
  final int typeId = 104;

  @override
  BulkOperationType read(BinaryReader reader) {
    return BulkOperationType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, BulkOperationType obj) {
    writer.writeByte(obj.index);
  }
}

class PerformanceAlertTypeAdapter extends TypeAdapter<PerformanceAlertType> {
  @override
  final int typeId = 105;

  @override
  PerformanceAlertType read(BinaryReader reader) {
    return PerformanceAlertType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PerformanceAlertType obj) {
    writer.writeByte(obj.index);
  }
}

class AnalyticsTypeAdapter extends TypeAdapter<AnalyticsType> {
  @override
  final int typeId = 106;

  @override
  AnalyticsType read(BinaryReader reader) {
    return AnalyticsType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AnalyticsType obj) {
    writer.writeByte(obj.index);
  }
}

class ChartTypeAdapter extends TypeAdapter<ChartType> {
  @override
  final int typeId = 107;

  @override
  ChartType read(BinaryReader reader) {
    return ChartType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ChartType obj) {
    writer.writeByte(obj.index);
  }
}

class TrendDirectionAdapter extends TypeAdapter<TrendDirection> {
  @override
  final int typeId = 108;

  @override
  TrendDirection read(BinaryReader reader) {
    return TrendDirection.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TrendDirection obj) {
    writer.writeByte(obj.index);
  }
}

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final int typeId = 109;

  @override
  ActivityType read(BinaryReader reader) {
    return ActivityType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    writer.writeByte(obj.index);
  }
}

class GradeAdapter extends TypeAdapter<Grade> {
  @override
  final int typeId = 110;

  @override
  Grade read(BinaryReader reader) {
    return Grade.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, Grade obj) {
    writer.writeByte(obj.index);
  }
}

class PeriodTypeAdapter extends TypeAdapter<PeriodType> {
  @override
  final int typeId = 111;

  @override
  PeriodType read(BinaryReader reader) {
    return PeriodType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PeriodType obj) {
    writer.writeByte(obj.index);
  }
}

class ClassTypeAdapter extends TypeAdapter<ClassType> {
  @override
  final int typeId = 112;

  @override
  ClassType read(BinaryReader reader) {
    return ClassType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ClassType obj) {
    writer.writeByte(obj.index);
  }
}

class SubjectTypeAdapter extends TypeAdapter<SubjectType> {
  @override
  final int typeId = 113;

  @override
  SubjectType read(BinaryReader reader) {
    return SubjectType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, SubjectType obj) {
    writer.writeByte(obj.index);
  }
}

class WorkloadTrendAdapter extends TypeAdapter<WorkloadTrend> {
  @override
  final int typeId = 114;

  @override
  WorkloadTrend read(BinaryReader reader) {
    return WorkloadTrend.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, WorkloadTrend obj) {
    writer.writeByte(obj.index);
  }
}

// Note: Complex model adapters (SyncResult, SyncConflict, etc.) are automatically
// generated by hive_generator in sync_models.g.dart and imported via the models
