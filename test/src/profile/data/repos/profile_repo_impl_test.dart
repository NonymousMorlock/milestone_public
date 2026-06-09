import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/profile/data/datasources/profile_remote_data_src.dart';
import 'package:milestone/src/profile/data/repos/profile_repo_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRemoteDataSrc extends Mock implements ProfileRemoteDataSrc {}

void main() {
  late ProfileRemoteDataSrc remoteDataSrc;
  late ProfileRepoImpl repoImpl;

  setUp(() {
    remoteDataSrc = MockProfileRemoteDataSrc();
    repoImpl = ProfileRepoImpl(remoteDataSrc);
  });

  const tException = ServerException(message: 'message', statusCode: 'UNKNOWN');

  group('updateProfileImage', () {
    test(
      'should return [Right] when call to remote source is successful',
      () async {
        when(() => remoteDataSrc.updateProfileImage(any())).thenAnswer(
          (_) async => Future.value(),
        );

        final result = await repoImpl.updateProfileImage('newImage');

        expect(result, equals(const Right<Failure, void>(null)));

        verify(() => remoteDataSrc.updateProfileImage('newImage')).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );

    test(
      'should return [Left<ServerFailure>] when call to remote source is '
      'unsuccessful',
      () async {
        when(
          () => remoteDataSrc.updateProfileImage(any()),
        ).thenThrow(tException);

        final result = await repoImpl.updateProfileImage('newImage');

        expect(
          result,
          equals(
            Left<ServerFailure, void>(ServerFailure.fromException(tException)),
          ),
        );

        verify(() => remoteDataSrc.updateProfileImage('newImage')).called(1);
        verifyNoMoreInteractions(remoteDataSrc);
      },
    );
  });
}
