// File: test/unit/core_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huliot_so_flutter/core/errors/failures.dart';
import 'package:huliot_so_flutter/core/utils/logger.dart';

void main() {
  group('Core Infrastructure Tests', () {
    test('Failures instantiate with descriptive messages', () {
      final serverFail = ServerFailure('Firestore unavailable');
      expect(serverFail.message, equals('Firestore unavailable'));
      expect(serverFail, isA<Failure>());

      final cacheFail = CacheFailure('Local cache corrupted');
      expect(cacheFail.message, equals('Local cache corrupted'));
      expect(cacheFail, isA<Failure>());

      final netFail = NetworkFailure('Connection timed out');
      expect(netFail.message, equals('Connection timed out'));
      expect(netFail, isA<Failure>());
    });

    test('AppLogger log and error run safely without throwing', () {
      expect(() => AppLogger.log('System test message'), returnsNormally);
      expect(() => AppLogger.error('Test error message', Exception('Mock exception')), returnsNormally);
    });
  });
}

