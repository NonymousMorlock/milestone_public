import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/data/datasources/project_remote_data_src.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/repos/project_repo.dart';

class ProjectRepoImpl implements ProjectRepo {
  const ProjectRepoImpl(this._remoteDataSource);

  final ProjectRemoteDataSrc _remoteDataSource;

  @override
  ResultFuture<void> addProject(Project project) async {
    try {
      await _remoteDataSource.addProject(project);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> deleteProject(String projectId) async {
    try {
      await _remoteDataSource.deleteProject(projectId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> editProjectDetails({
    required String projectId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      await _remoteDataSource.editProjectDetails(
        projectId: projectId,
        updateData: updateData,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<Project> getProjectById(String projectId) async {
    try {
      final result = await _remoteDataSource.getProjectById(projectId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultStream<List<Project>> getProjects({
    required bool detailed,
    int? limit,
    bool excludePendingDeletion = false,
  }) {
    return _remoteDataSource
        .getProjects(
          detailed: detailed,
          limit: limit,
          excludePendingDeletion: excludePendingDeletion,
        )
        .transform(
          StreamTransformer<
            List<ProjectModel>,
            Either<Failure, List<Project>>
          >.fromHandlers(
            handleData: (data, sink) {
              sink.add(Right(data));
            },
            handleError: (error, stackTrace, sink) {
              if (error is ServerException) {
                sink.add(
                  Left(
                    ServerFailure(
                      message: error.message,
                      statusCode: error.statusCode,
                    ),
                  ),
                );
              } else {
                sink.add(
                  Left(
                    ServerFailure(
                      message: error.toString(),
                      statusCode: 'Internal Error',
                    ),
                  ),
                );
              }
            },
          ),
        );
  }

  @override
  ResultFuture<List<String>> getUserTools() async {
    try {
      final result = await _remoteDataSource.getUserTools();
      return Right(result);
    } on ServerException catch (exception) {
      return Left(ServerFailure.fromException(exception));
    }
  }

  @override
  ResultFuture<void> removeUserTool(String toolName) async {
    try {
      await _remoteDataSource.removeUserTool(toolName);
      return const Right(null);
    } on ServerException catch (exception) {
      return Left(ServerFailure.fromException(exception));
    }
  }
}
