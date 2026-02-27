import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/utils/constants/network_contants.dart';
import 'package:milestone/core/utils/network_utils.dart';

abstract interface class ProfileRemoteDataSrc {
  const ProfileRemoteDataSrc();

  Future<void> updateProfileImage(String? imagePath);
}

class ProfileRemoteDataSrcImpl implements ProfileRemoteDataSrc {
  const ProfileRemoteDataSrcImpl({
    required FirebaseStorage storage,
    required FirebaseAuth auth,
  })  : _storage = storage,
        _auth = auth;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  @override
  Future<void> updateProfileImage(String? imagePath) async {
    try {
      await NetworkUtils.authorizeUser(_auth);

      final user = _auth.currentUser!;

      String? imageUrl;

      if (imagePath == null) {
        await _storage
            .ref()
            .child('profile_avatars/lancers/${user.uid}')
            .delete();
        imageUrl = NetworkConstants.defaultAvatar;
      } else {
        final contentType = imagePath.split('.').last;
        final imageRef = _storage.ref().child(
              'profile_avatars/lancers/${user.uid}',
            );
        await imageRef.putFile(
          File(imagePath),
          SettableMetadata(contentType: 'image/$contentType'),
        );
        imageUrl = await imageRef.getDownloadURL();
      }

      await user.updatePhotoURL(imageUrl);
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      debugPrintStack(stackTrace: e.stackTrace);
      throw ServerException(
        message: e.message ?? 'Unknown Error Occurred',
        statusCode: e.code,
      );
    } on ServerException {
      rethrow;
    } on Exception catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const ServerException(
        message: 'Something went wrong',
        statusCode: 'UPDATE_IMAGE_UNK',
      );
    }
  }
}
