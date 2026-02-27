import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

abstract class ClientRepo {
  ResultFuture<Client> addClient(Client client);

  ResultFuture<void> editClient({
    required String clientId,
    required DataMap updatedClient,
  });

  ResultFuture<void> deleteClient(String clientId);

  ResultFuture<Client> getClientById(String clientId);

  ResultFuture<List<Client>> getClients();

  ResultFuture<List<Project>> getClientProjects({
    required String clientId,
    required bool detailed,
  });
}
