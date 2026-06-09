import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/src/profile/domain/usecases/update_profile_image.dart';
import 'package:milestone/src/profile/presentation/app/adapter/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateProfileImage extends Mock implements UpdateProfileImage {}

void main() {
  late UpdateProfileImage updateProfileImage;
  late ProfileCubit cubit;

  setUp(() {
    updateProfileImage = MockUpdateProfileImage();

    cubit = ProfileCubit(updateProfileImage: updateProfileImage);
  });

  test(
    'initial state should be [ProfileInitial]',
    () => expect(cubit.state, isA<ProfileInitial>()),
  );

  const tFailure = ServerFailure(
    message: 'Unknown error occurred',
    statusCode: 'UNKNOWN',
  );

  group('updateProfileImage', () {
    blocTest<ProfileCubit, ProfileState>(
      'should emit [ProfileLoading, ProfileUpdated] when updateProfileImage '
      'is successful',
      build: () {
        when(
          () => updateProfileImage(any()),
        ).thenAnswer((_) async => const Right(null));

        return cubit;
      },
      act: (cubit) => cubit.updateProfileImage('newImage'),
      expect: () => [
        const ProfileLoading(),
        const ProfileUpdated(),
      ],
      verify: (_) => [
        verify(() => updateProfileImage('newImage')).called(1),
        verifyNoMoreInteractions(updateProfileImage),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'should emit [ProfileLoading, ProfileError] when updateProfileImage '
      'is unsuccessful',
      build: () {
        when(() => updateProfileImage(any())).thenAnswer(
          (_) async => const Left(tFailure),
        );

        return cubit;
      },
      act: (cubit) => cubit.updateProfileImage('newImage'),
      expect: () => [
        isA<ProfileLoading>(),
        ProfileError(tFailure.errorMessage),
      ],
      verify: (_) => [
        verify(() => updateProfileImage('newImage')).called(1),
        verifyNoMoreInteractions(updateProfileImage),
      ],
    );
  });
}
