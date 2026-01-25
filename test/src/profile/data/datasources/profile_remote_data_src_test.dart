import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/core/utils/constants/network_contants.dart';
import 'package:milestone/src/profile/data/datasources/profile_remote_data_src.dart';

import '../../../../helpers/helpers.dart';

void main() {
  late MockFirebase firebase;
  late ProfileRemoteDataSrc profileRemoteDataSrc;

  late User tCurrentUser;

  setUp(() async {
    firebase = MockFirebase();
    await firebase.initAuth();
    await firebase.initStorage();
    profileRemoteDataSrc = ProfileRemoteDataSrcImpl(
      storage: firebase.storage,
      auth: firebase.auth,
    );
    tCurrentUser = firebase.auth.currentUser!;
  });

  const tFileImage = '/home/akundadababalei/StudioProjects/milestone/test'
      '/fixtures/project.png';

  group('updateProfileImage', () {
    test(
      'should store the image in the firebase storage at the correct path and'
      ' update the currentUser',
      () async {
        await profileRemoteDataSrc.updateProfileImage(tFileImage);

        final imageRef = await firebase.storage
            .ref()
            .child('profile_avatars/lancers/${tCurrentUser.uid}')
            .getDownloadURL();

        expect(imageRef, isNotNull);
        expect(tCurrentUser.photoURL, equals(imageRef));
      },
    );

    test(
      'should delete the image storage and replace auth user image with '
      '[NetworkConstants.defaultAvatar] when null is passed as the image',
      () async {
        await profileRemoteDataSrc.updateProfileImage(tFileImage);

        final imageRef = await firebase.storage
            .ref()
            .child('profile_avatars/lancers/')
            .listAll();

        expect(imageRef.items, isNotEmpty);
        expect(tCurrentUser.photoURL, endsWith(tCurrentUser.uid));

        await profileRemoteDataSrc.updateProfileImage(null);

        final deletedImageRef = await firebase.storage
            .ref()
            .child('profile_avatars/lancers/')
            .listAll();

        expect(deletedImageRef.items, isEmpty);
        expect(tCurrentUser.photoURL, equals(NetworkConstants.defaultAvatar));
      },
    );
  });
}
