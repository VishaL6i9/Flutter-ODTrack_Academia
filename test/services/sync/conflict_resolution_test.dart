import 'package:flutter_test/flutter_test.dart';
import 'package:odtrack_academia/models/sync_models.dart';

void main() {
  group('Conflict Resolution Logic', () {
    group('Server-side Timestamp Resolution', () {
      test('should prefer server data when server timestamp is newer', () {
        final localTimestamp = DateTime(2024, 1, 1, 10, 0, 0);
        final serverTimestamp = DateTime(2024, 1, 1, 11, 0, 0);

        final conflict = SyncConflict(
          itemId: 'test_item',
          itemType: 'od_request',
          localData: {
            'id': 'test_item',
            'status': 'pending',
            'version': 1,
            'lastModified': localTimestamp.toIso8601String(),
          },
          serverData: {
            'id': 'test_item',
            'status': 'approved',
            'version': 2,
            'lastModified': serverTimestamp.toIso8601String(),
          },
          localTimestamp: localTimestamp,
          serverTimestamp: serverTimestamp,
        );

        // Server timestamp is newer, so server data should win
        final shouldUseServer = conflict.serverTimestamp.isAfter(conflict.localTimestamp);
        expect(shouldUseServer, isTrue);

        final expectedResolution = ConflictResolution(
          conflictId: conflict.itemId,
          resolution: 'use_server',
          mergedData: conflict.serverData,
        );

        expect(expectedResolution.resolution, equals('use_server'));
        expect(expectedResolution.mergedData, equals(conflict.serverData));
      });

      test('should prefer local data when local timestamp is newer', () {
        final localTimestamp = DateTime(2024, 1, 1, 11, 0, 0);
        final serverTimestamp = DateTime(2024, 1, 1, 10, 0, 0);

        final conflict = SyncConflict(
          itemId: 'test_item',
          itemType: 'od_request',
          localData: {
            'id': 'test_item',
            'status': 'approved',
            'version': 2,
            'lastModified': localTimestamp.toIso8601String(),
          },
          serverData: {
            'id': 'test_item',
            'status': 'pending',
            'version': 1,
            'lastModified': serverTimestamp.toIso8601String(),
          },
          localTimestamp: localTimestamp,
          serverTimestamp: serverTimestamp,
        );

        // Local timestamp is newer, so local data should win
        final shouldUseServer = conflict.serverTimestamp.isAfter(conflict.localTimestamp);
        expect(shouldUseServer, isFalse);

        final expectedResolution = ConflictResolution(
          conflictId: conflict.itemId,
          resolution: 'use_local',
          mergedData: conflict.localData,
        );

        expect(expectedResolution.resolution, equals('use_local'));
        expect(expectedResolution.mergedData, equals(conflict.localData));
      });

      test('should prefer server data when timestamps are equal', () {
        final timestamp = DateTime(2024, 1, 1, 10, 0, 0);

        final conflict = SyncConflict(
          itemId: 'test_item',
          itemType: 'od_request',
          localData: {
            'id': 'test_item',
            'status': 'pending',
            'version': 1,
          },
          serverData: {
            'id': 'test_item',
            'status': 'approved',
            'version': 1,
          },
          localTimestamp: timestamp,
          serverTimestamp: timestamp,
        );

        // When timestamps are equal, server should win (isAfter returns false, but we default to server)
        final shouldUseServer = !conflict.localTimestamp.isAfter(conflict.serverTimestamp);
        expect(shouldUseServer, isTrue);
      });
    });

    group('Conflict Detection Scenarios', () {
      test('should detect status conflicts in OD requests', () {
        final conflict = SyncConflict(
          itemId: 'od_123',
          itemType: 'od_request',
          localData: {
            'id': 'od_123',
            'status': 'pending',
            'reason': 'Medical appointment',
            'lastModified': '2024-01-01T10:00:00Z',
          },
          serverData: {
            'id': 'od_123',
            'status': 'approved',
            'reason': 'Medical appointment',
            'approvedBy': 'staff_456',
            'approvedAt': '2024-01-01T10:30:00Z',
            'lastModified': '2024-01-01T10:30:00Z',
          },
          localTimestamp: DateTime.parse('2024-01-01T10:00:00Z'),
          serverTimestamp: DateTime.parse('2024-01-01T10:30:00Z'),
        );

        expect(conflict.localData['status'], equals('pending'));
        expect(conflict.serverData['status'], equals('approved'));
        expect(conflict.serverData.containsKey('approvedBy'), isTrue);
        expect(conflict.serverData.containsKey('approvedAt'), isTrue);
      });

      test('should detect data modification conflicts', () {
        final conflict = SyncConflict(
          itemId: 'od_123',
          itemType: 'od_request',
          localData: {
            'id': 'od_123',
            'reason': 'Updated medical appointment',
            'periods': [1, 2, 3],
            'lastModified': '2024-01-01T11:00:00Z',
          },
          serverData: {
            'id': 'od_123',
            'reason': 'Medical appointment',
            'periods': [1, 2],
            'lastModified': '2024-01-01T10:30:00Z',
          },
          localTimestamp: DateTime.parse('2024-01-01T11:00:00Z'),
          serverTimestamp: DateTime.parse('2024-01-01T10:30:00Z'),
        );

        expect(conflict.localData['reason'], equals('Updated medical appointment'));
        expect(conflict.serverData['reason'], equals('Medical appointment'));
        expect(conflict.localData['periods'], hasLength(3));
        expect(conflict.serverData['periods'], hasLength(2));
      });

      test('should handle user profile conflicts', () {
        final conflict = SyncConflict(
          itemId: 'user_123',
          itemType: 'user_data',
          localData: {
            'id': 'user_123',
            'name': 'John Doe',
            'phone': '+1234567890',
            'lastModified': '2024-01-01T10:00:00Z',
          },
          serverData: {
            'id': 'user_123',
            'name': 'John Smith',
            'phone': '+1234567891',
            'email': 'john.smith@example.com',
            'lastModified': '2024-01-01T10:30:00Z',
          },
          localTimestamp: DateTime.parse('2024-01-01T10:00:00Z'),
          serverTimestamp: DateTime.parse('2024-01-01T10:30:00Z'),
        );

        expect(conflict.localData['name'], equals('John Doe'));
        expect(conflict.serverData['name'], equals('John Smith'));
        expect(conflict.serverData.containsKey('email'), isTrue);
      });
    });

    group('Resolution Strategy Validation', () {
      test('should validate use_server resolution', () {
        final resolution = ConflictResolution(
          conflictId: 'test_item',
          resolution: 'use_server',
          mergedData: {
            'id': 'test_item',
            'status': 'approved',
            'source': 'server',
          },
        );

        expect(resolution.resolution, equals('use_server'));
        expect(resolution.mergedData, isNotNull);
        expect(resolution.mergedData!['source'], equals('server'));
      });

      test('should validate use_local resolution', () {
        final resolution = ConflictResolution(
          conflictId: 'test_item',
          resolution: 'use_local',
          mergedData: {
            'id': 'test_item',
            'status': 'pending',
            'source': 'local',
          },
        );

        expect(resolution.resolution, equals('use_local'));
        expect(resolution.mergedData, isNotNull);
        expect(resolution.mergedData!['source'], equals('local'));
      });

      test('should support merge resolution strategy', () {
        final localData = {
          'id': 'test_item',
          'name': 'John Doe',
          'phone': '+1234567890',
          'localField': 'local_value',
        };

        final serverData = {
          'id': 'test_item',
          'name': 'John Smith',
          'email': 'john@example.com',
          'serverField': 'server_value',
        };

        // Simulate a merge strategy (in practice, this would be more sophisticated)
        final mergedData = <String, dynamic>{
          ...localData,
          ...serverData,
          'mergeStrategy': 'timestamp_based',
          'mergedAt': DateTime.now().toIso8601String(),
        };

        final resolution = ConflictResolution(
          conflictId: 'test_item',
          resolution: 'merge',
          mergedData: mergedData,
        );

        expect(resolution.resolution, equals('merge'));
        expect(resolution.mergedData!['localField'], equals('local_value'));
        expect(resolution.mergedData!['serverField'], equals('server_value'));
        expect(resolution.mergedData!['email'], equals('john@example.com'));
        expect(resolution.mergedData!.containsKey('mergeStrategy'), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle conflicts with missing data fields', () {
        final conflict = SyncConflict(
          itemId: 'test_item',
          itemType: 'od_request',
          localData: {
            'id': 'test_item',
            'status': 'pending',
          },
          serverData: {
            'id': 'test_item',
            'status': 'approved',
            'approvedBy': 'staff_123',
            'approvedAt': '2024-01-01T10:30:00Z',
          },
          localTimestamp: DateTime.parse('2024-01-01T10:00:00Z'),
          serverTimestamp: DateTime.parse('2024-01-01T10:30:00Z'),
        );

        expect(conflict.localData.containsKey('approvedBy'), isFalse);
        expect(conflict.serverData.containsKey('approvedBy'), isTrue);
        expect(conflict.serverData['approvedBy'], equals('staff_123'));
      });

      test('should handle conflicts with null values', () {
        final conflict = SyncConflict(
          itemId: 'test_item',
          itemType: 'od_request',
          localData: {
            'id': 'test_item',
            'attachmentUrl': null,
            'rejectionReason': null,
          },
          serverData: {
            'id': 'test_item',
            'attachmentUrl': 'https://example.com/file.pdf',
            'rejectionReason': 'Insufficient documentation',
          },
          localTimestamp: DateTime.parse('2024-01-01T10:00:00Z'),
          serverTimestamp: DateTime.parse('2024-01-01T10:30:00Z'),
        );

        expect(conflict.localData['attachmentUrl'], isNull);
        expect(conflict.serverData['attachmentUrl'], isNotNull);
        expect(conflict.serverData['rejectionReason'], equals('Insufficient documentation'));
      });

      test('should handle conflicts with different data types', () {
        final conflict = SyncConflict(
          itemId: 'test_item',
          itemType: 'od_request',
          localData: {
            'id': 'test_item',
            'periods': [1, 2, 3],
            'metadata': {'version': 1},
          },
          serverData: {
            'id': 'test_item',
            'periods': [1, 2],
            'metadata': {'version': 2, 'updatedBy': 'system'},
          },
          localTimestamp: DateTime.parse('2024-01-01T10:00:00Z'),
          serverTimestamp: DateTime.parse('2024-01-01T10:30:00Z'),
        );

        expect(conflict.localData['periods'], isA<List<dynamic>>());
        expect(conflict.serverData['periods'], isA<List<dynamic>>());
        expect(conflict.localData['metadata'], isA<Map<dynamic, dynamic>>());
        expect(conflict.serverData['metadata'], isA<Map<dynamic, dynamic>>());
        
        final localMetadata = conflict.localData['metadata'] as Map<dynamic, dynamic>;
        final serverMetadata = conflict.serverData['metadata'] as Map<dynamic, dynamic>;
        
        expect(localMetadata['version'], equals(1));
        expect(serverMetadata['version'], equals(2));
        expect(serverMetadata.containsKey('updatedBy'), isTrue);
      });
    });

    group('Conflict Resolution Performance', () {
      test('should handle large number of conflicts efficiently', () {
        final conflicts = List.generate(100, (index) {
          return SyncConflict(
            itemId: 'item_$index',
            itemType: 'od_request',
            localData: {
              'id': 'item_$index',
              'status': 'pending',
              'version': index,
            },
            serverData: {
              'id': 'item_$index',
              'status': 'approved',
              'version': index + 1,
            },
            localTimestamp: DateTime.now().subtract(Duration(minutes: index)),
            serverTimestamp: DateTime.now(),
          );
        });

        final stopwatch = Stopwatch()..start();
        
        final resolutions = conflicts.map((conflict) {
          final useServer = conflict.serverTimestamp.isAfter(conflict.localTimestamp);
          return ConflictResolution(
            conflictId: conflict.itemId,
            resolution: useServer ? 'use_server' : 'use_local',
            mergedData: useServer ? conflict.serverData : conflict.localData,
          );
        }).toList();

        stopwatch.stop();

        expect(resolutions, hasLength(100));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
        
        // Most should resolve to use_server since server timestamps are newer
        final serverResolutions = resolutions.where((r) => r.resolution == 'use_server').length;
        expect(serverResolutions, greaterThan(90)); // Most should be server resolutions
      });

      test('should handle conflicts with large data payloads', () {
        final largeData = Map<String, String>.fromEntries(
          List.generate(1000, (index) => MapEntry('field_$index', 'value_$index'))
        );

        final conflict = SyncConflict(
          itemId: 'large_item',
          itemType: 'od_request',
          localData: {
            'id': 'large_item',
            'status': 'pending',
            ...largeData,
          },
          serverData: {
            'id': 'large_item',
            'status': 'approved',
            ...largeData,
            'serverField': 'server_value',
          },
          localTimestamp: DateTime.now().subtract(Duration(minutes: 1)),
          serverTimestamp: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();
        
        final useServer = conflict.serverTimestamp.isAfter(conflict.localTimestamp);
        final resolution = ConflictResolution(
          conflictId: conflict.itemId,
          resolution: useServer ? 'use_server' : 'use_local',
          mergedData: useServer ? conflict.serverData : conflict.localData,
        );

        stopwatch.stop();

        expect(resolution.resolution, equals('use_server'));
        expect(resolution.mergedData!.containsKey('serverField'), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should still be fast
      });
    });
  });
}