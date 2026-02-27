import 'package:milestone/core/usecase/usecase.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/profile/domain/repos/profile_repo.dart';

class UpdateProfileImage extends UsecaseWithParams<void, String?> {
  const UpdateProfileImage(this._repo);

  final ProfileRepo _repo;

  @override
  ResultFuture<void> call(String? params) => _repo.updateProfileImage(params);
}
