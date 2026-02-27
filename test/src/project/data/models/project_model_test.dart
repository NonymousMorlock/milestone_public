import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

import '../../../../fixtures/fixture_reader.dart';

void main() {
  final startDate = <String, int>{
    '_seconds': 1677483548,
    '_nanoseconds': 123456000,
  };
  final timestamp = Timestamp(
    startDate['_seconds']!,
    startDate['_nanoseconds']!,
  );
  final tProjectModel = ProjectModel.empty().copyWith(
    startDate: timestamp.toDate(),
  );

  final json = fixture('project.json');
  final map = jsonDecode(json) as DataMap;
  map['startDate'] = timestamp;

  group('ProjectModel', () {
    test('should be a subclass of [Project] entity', () async {
      expect(tProjectModel, isA<Project>());
    });

    group('fromMap', () {
      test('should return a valid [ProjectModel] when the JSON is not null',
          () async {
        final result = ProjectModel.fromMap(map);
        expect(result, tProjectModel);
      });
    });

    group('toMap', () {
      test('should return a Dart map containing the proper data', () async {
        final result = tProjectModel.toMap();
        expect(result, map);
      });
    });

    group('copyWith', () {
      test('should return a new [ProjectModel] with the same values', () async {
        final result = tProjectModel.copyWith(id: '');
        expect(result.id, equals(''));
      });
    });
  });
}
