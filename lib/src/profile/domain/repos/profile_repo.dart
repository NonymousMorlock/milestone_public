import 'package:milestone/core/utils/typedefs.dart';

abstract interface class ProfileRepo {
  const ProfileRepo();

  ResultFuture<void> updateProfileImage(String? imagePath);
}
