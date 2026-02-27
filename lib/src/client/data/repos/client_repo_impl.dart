import 'package:dartz/dartz.dart';
import 'package:milestone/core/errors/exceptions.dart';
import 'package:milestone/core/errors/failure.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/data/datasources/client_remote_data_src.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ClientRepoImpl implements ClientRepo {
  const ClientRepoImpl(this._remoteDataSource);

  final ClientRemoteDataSrc _remoteDataSource;

  @override
  ResultFuture<Client> addClient(Client client) async {
    try {
      final result = await _remoteDataSource.addClient(client);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> editClient({
    required String clientId,
    required DataMap updatedClient,
  }) async {
    try {
      await _remoteDataSource.editClient(
        clientId: clientId,
        updatedClient: updatedClient,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<void> deleteClient(String clientId) async {
    try {
      await _remoteDataSource.deleteClient(clientId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<Client> getClientById(String clientId) async {
    try {
      final result = await _remoteDataSource.getClientById(clientId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<Client>> getClients() async {
    try {
      final result = await _remoteDataSource.getClients();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<Project>> getClientProjects({
    required String clientId,
    required bool detailed,
  }) async {
    try {
      final result = await _remoteDataSource.getClientProjects(
        clientId: clientId,
        detailed: detailed,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
