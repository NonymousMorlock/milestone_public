import 'package:equatable/equatable.dart';
import 'package:milestone/app/routing/app_routes.dart';

enum ClientEditorRecoveryDisposition {
  selectCreatedClient,
  refreshClientList,
  refreshClientDetail,
}

sealed class AddClientRouteSuccessMode extends Equatable {
  const AddClientRouteSuccessMode({
    required this.recoveryTargetLocation,
    required this.recoveryDisposition,
    required this.recoveryClaimKey,
  });

  const factory AddClientRouteSuccessMode.returnCreatedClient({
    required String recoveryTargetLocation,
  }) = _ReturnCreatedClientAddClientRouteSuccessMode;

  const factory AddClientRouteSuccessMode.returnCreatedClientAndRefreshList() =
      _ReturnCreatedClientAndRefreshListAddClientRouteSuccessMode;

  const factory AddClientRouteSuccessMode.goToClients() =
      _GoToClientsAddClientRouteSuccessMode;

  final String recoveryTargetLocation;
  final ClientEditorRecoveryDisposition recoveryDisposition;
  final String recoveryClaimKey;

  String get kind => switch (this) {
    _ReturnCreatedClientAddClientRouteSuccessMode() => 'returnCreatedClient',
    _ReturnCreatedClientAndRefreshListAddClientRouteSuccessMode() =>
      'returnCreatedClientAndRefreshList',
    _GoToClientsAddClientRouteSuccessMode() => 'goToClients',
  };

  @override
  List<Object?> get props => [
    recoveryTargetLocation,
    recoveryDisposition,
    recoveryClaimKey,
    kind,
  ];
}

final class _ReturnCreatedClientAddClientRouteSuccessMode
    extends AddClientRouteSuccessMode {
  const _ReturnCreatedClientAddClientRouteSuccessMode({
    required super.recoveryTargetLocation,
  }) : super(
         recoveryDisposition:
             ClientEditorRecoveryDisposition.selectCreatedClient,
         recoveryClaimKey:
             'client-add:returnCreatedClient:$recoveryTargetLocation',
       );
}

final class _ReturnCreatedClientAndRefreshListAddClientRouteSuccessMode
    extends AddClientRouteSuccessMode {
  const _ReturnCreatedClientAndRefreshListAddClientRouteSuccessMode()
    : super(
        recoveryTargetLocation: AppRoutes.clients,
        recoveryDisposition: ClientEditorRecoveryDisposition.refreshClientList,
        recoveryClaimKey:
            'client-add:returnCreatedClientAndRefreshList:${AppRoutes.clients}',
      );
}

final class _GoToClientsAddClientRouteSuccessMode
    extends AddClientRouteSuccessMode {
  const _GoToClientsAddClientRouteSuccessMode()
    : super(
        recoveryTargetLocation: AppRoutes.clients,
        recoveryDisposition: ClientEditorRecoveryDisposition.refreshClientList,
        recoveryClaimKey: 'client-add:goToClients:${AppRoutes.clients}',
      );
}

sealed class EditClientRouteSuccessMode extends Equatable {
  const EditClientRouteSuccessMode({
    required this.recoveryTargetLocation,
    required this.recoveryDisposition,
  });

  const factory EditClientRouteSuccessMode.returnUpdatedFlag({
    required String recoveryTargetLocation,
  }) = _ReturnUpdatedFlagEditClientRouteSuccessMode;

  factory EditClientRouteSuccessMode.goToClientDetails({
    required String clientId,
  }) = _GoToClientDetailsEditClientRouteSuccessMode;

  final String recoveryTargetLocation;
  final ClientEditorRecoveryDisposition recoveryDisposition;

  String get kind => switch (this) {
    _ReturnUpdatedFlagEditClientRouteSuccessMode() => 'returnUpdatedFlag',
    _GoToClientDetailsEditClientRouteSuccessMode() => 'goToClientDetails',
  };

  @override
  List<Object?> get props => [
    recoveryTargetLocation,
    recoveryDisposition,
    kind,
  ];
}

final class _ReturnUpdatedFlagEditClientRouteSuccessMode
    extends EditClientRouteSuccessMode {
  const _ReturnUpdatedFlagEditClientRouteSuccessMode({
    required super.recoveryTargetLocation,
  }) : super(
         recoveryDisposition:
             ClientEditorRecoveryDisposition.refreshClientDetail,
       );
}

final class _GoToClientDetailsEditClientRouteSuccessMode
    extends EditClientRouteSuccessMode {
  _GoToClientDetailsEditClientRouteSuccessMode({
    required String clientId,
  }) : super(
         recoveryTargetLocation: AppRoutes.clientDetails(clientId),
         recoveryDisposition:
             ClientEditorRecoveryDisposition.refreshClientDetail,
       );
}
