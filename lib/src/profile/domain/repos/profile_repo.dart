// This interface is intentionally kept at the domain boundary even with one method so the data layer can remain replaceable/testable
// ignore_for_file: one_member_abstracts
import 'package:milestone/core/utils/typedefs.dart';

abstract interface class ProfileRepo {
  const ProfileRepo();

  ResultFuture<void> updateProfileImage(String? imagePath);
}
