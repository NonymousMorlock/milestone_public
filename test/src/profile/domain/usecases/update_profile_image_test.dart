import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/profile/domain/repos/profile_repo.dart';
import 'package:milestone/src/profile/domain/usecases/update_profile_image.dart';
import 'package:mocktail/mocktail.dart';

import 'profile_repo.mock.dart';

void main() {
  late ProfileRepo repo;
  late UpdateProfileImage usecase;

  setUp(() {
    repo = MockProfileRepo();
    usecase = UpdateProfileImage(repo);
  });

  test(
    'should call [ProfileRepo.updateProfileImage]',
    () async {
      when(() => repo.updateProfileImage(any())).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await usecase('newImage');

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => repo.updateProfileImage('newImage')).called(1);
      verifyNoMoreInteractions(repo);
    },
  );
}
