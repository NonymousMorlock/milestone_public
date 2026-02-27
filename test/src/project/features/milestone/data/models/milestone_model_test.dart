import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

import '../../../../../../fixtures/fixture_reader.dart';

void main() {
  final date = {
    '_seconds': 1677483548,
    '_nanoseconds': 123456000,
  };

  final timestamp = Timestamp(date['_seconds']!, date['_nanoseconds']!);

  final tMilestoneModel = MilestoneModel.empty().copyWith(
    dateCreated: timestamp.toDate(),
  );
  final json = fixture('milestone.json');
  final map = jsonDecode(json) as DataMap;
  map['dateCreated'] = timestamp;

  group('MilestoneModel', () {
    test('should be a subclass of [Milestone] entity', () async {
      expect(tMilestoneModel, isA<Milestone>());
    });

    group('fromMap', () {
      test('should return a valid [MilestoneModel] when the JSON is not null',
          () async {
        final result = MilestoneModel.fromMap(map);
        expect(result, tMilestoneModel);
      });
    });

    group('toMap', () {
      test('should return a Dart map containing the proper data', () async {
        final result = tMilestoneModel.toMap()
          ..remove('dateCreated')
          ..remove('lastUpdated')
          ..remove('startDate')
          ..remove('endDate');
        expect(result, map..remove('dateCreated'));
      });
    });

    group('copyWith', () {
      test('should return a new [MilestoneModel] with the same values',
          () async {
        final result = tMilestoneModel.copyWith(id: '');
        expect(result.id, equals(''));
      });
    });
  });
}
