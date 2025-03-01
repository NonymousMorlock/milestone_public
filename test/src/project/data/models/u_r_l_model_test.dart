import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/data/models/u_r_l_model.dart';
import 'package:milestone/src/project/domain/entities/u_r_l.dart';

import '../../../../fixtures/fixture_reader.dart';

void main() {
  const tURLModel = URLModel.empty();

  group('URLModel', () {
    test('should be a subclass of [URL] entity', () async {
      expect(tURLModel, isA<URL>());
    });

    group('fromMap', () {
      test('should return a valid [URLModel] when the JSON is not null',
          () async {
        final map = jsonDecode(fixture('u_r_l.json')) as DataMap;
        final result = URLModel.fromMap(map);
        expect(result, tURLModel);
      });
    });

    group('fromJson', () {
      test('should return a valid [URLModel] when the JSON is not null',
          () async {
        final json = fixture('u_r_l.json');
        final result = URLModel.fromJson(json);
        expect(result, tURLModel);
      });
    });

    group('toMap', () {
      test('should return a Dart map containing the proper data', () async {
        final map = jsonDecode(fixture('u_r_l.json')) as DataMap;
        final result = tURLModel.toMap();
        expect(result, map);
      });
    });

    group('toJson', () {
      test('should return a JSON string containing the proper data', () async {
        final json = jsonEncode(jsonDecode(fixture('u_r_l.json')));
        final result = tURLModel.toJson();
        expect(result, json);
      });
    });

    group('copyWith', () {
      test('should return a new [URLModel] with the same values', () async {
        final result = tURLModel.copyWith(url: '');
        expect(result.url, equals(''));
      });
    });
  });
}
