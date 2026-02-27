import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:milestone/src/profile/domain/usecases/update_profile_image.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required UpdateProfileImage updateProfileImage,
  })  : _updateProfileImage = updateProfileImage,
        super(const ProfileInitial());

  final UpdateProfileImage _updateProfileImage;

  Future<void> updateProfileImage(String? image) async {
    emit(const ProfileLoading());
    final result = await _updateProfileImage(image);

    result.fold(
      (failure) => emit(ProfileError(failure.errorMessage)),
      (_) => emit(const ProfileUpdated()),
    );
  }
}
