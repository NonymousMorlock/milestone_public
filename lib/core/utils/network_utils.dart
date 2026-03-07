import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/extensions/string_extensions.dart';

abstract class NetworkUtils {
  const NetworkUtils();

  static Future<void> authorizeUser(FirebaseAuth auth) async {
    final user = auth.currentUser;
    if (user == null) {
      debugPrint('Error occurred: Unauthorized user access');
      debugPrintStack();
      throw const ServerException(
        message: 'Unauthorized user access',
        statusCode: 'UnauthorizedError',
      );
    }
  }

  static T handleRemoteSourceException<T>(
    Object e, {
    required String repositoryName,
    required String methodName,
    String? errorMessage,
    String? statusCode,
    StackTrace? stackTrace,
  }) {
    log(
      'Error Occurred',
      name: '$repositoryName.$methodName',
      error: e,
      stackTrace: stackTrace ?? StackTrace.current,
      level: 1200,
    );
    throw ServerException(
      message: errorMessage ?? 'Something went wrong',
      statusCode: statusCode ?? '${methodName.snakeCase.toUpperCase()}UNKNOWN',
    );
  }
}
