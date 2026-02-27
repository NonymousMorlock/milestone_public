import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/entities/client.dart';

import '../../../../fixtures/fixture_reader.dart';

void main() {
  final dateCreated = {'_seconds': 1677483548, '_nanoseconds': 123456000};
  final timestamp = Timestamp(
    dateCreated['_seconds']!,
    dateCreated['_nanoseconds']!,
  );
  final tClientModel = ClientModel.empty().copyWith(
    dateCreated: timestamp.toDate(),
  );

  final json = fixture('client.json');
  final map = jsonDecode(json) as DataMap;
  map['dateCreated'] = timestamp;

  group('ClientModel', () {
    test('should be a subclass of [Client] entity', () async {
      expect(tClientModel, isA<Client>());
    });

    group('fromMap', () {
      test('should return a valid [ClientModel] when the JSON is not null',
          () async {
        final result = ClientModel.fromMap(map);
        expect(result, tClientModel);
      });
    });

    group('toMap', () {
      test('should return a Dart map containing the proper data', () async {
        final result = tClientModel.toMap()..remove('dateCreated');
        expect(result, map..remove('dateCreated'));
      });
    });

    group('copyWith', () {
      test('should return a new [ClientModel] with the same values', () async {
        final result = tClientModel.copyWith(id: '');
        expect(result.id, equals(''));
      });
    });
  });
}
