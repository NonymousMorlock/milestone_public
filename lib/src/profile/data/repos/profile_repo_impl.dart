import 'package:dartz/dartz.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/profile/data/datasources/profile_remote_data_src.dart';
import 'package:milestone/src/profile/domain/repos/profile_repo.dart';

class ProfileRepoImpl implements ProfileRepo {
  const ProfileRepoImpl(this._remoteDataSrc);

  final ProfileRemoteDataSrc _remoteDataSrc;

  @override
  ResultFuture<void> updateProfileImage(String? imagePath) async {
    try {
      await _remoteDataSrc.updateProfileImage(imagePath);
      return const Right(null);
    } on ServerException catch (exception) {
      return Left(ServerFailure.fromException(exception));
    }
  }
}
