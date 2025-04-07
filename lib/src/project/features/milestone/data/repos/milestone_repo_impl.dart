import 'package:dartz/dartz.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/data/datasources/milestone_remote_data_src.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';
import 'package:milestone/src/project/features/milestone/domain/repos/milestone_repo.dart';

class MilestoneRepoImpl implements MilestoneRepo {
  const MilestoneRepoImpl(this._remoteDataSource);

  final MilestoneRemoteDataSrc _remoteDataSource;

  @override
  ResultFuture<void> addMilestone(Milestone milestone) async {
    try {
      await _remoteDataSource.addMilestone(milestone);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> editMilestone({
    required String projectId,
    required String milestoneId,
    required DataMap updatedMilestone,
  }) async {
    try {
      await _remoteDataSource.editMilestone(
        projectId: projectId,
        milestoneId: milestoneId,
        updatedMilestone: updatedMilestone,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<Milestone>> getMilestones(String projectId) async {
    try {
      final result = await _remoteDataSource.getMilestones(projectId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> deleteMilestone({
    required String projectId,
    required String milestoneId,
  }) async {
    try {
      await _remoteDataSource.deleteMilestone(
        projectId: projectId,
        milestoneId: milestoneId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<Milestone> getMilestoneById({
    required String projectId,
    required String milestoneId,
  }) async {
    try {
      final result = await _remoteDataSource.getMilestoneById(
        projectId: projectId,
        milestoneId: milestoneId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
