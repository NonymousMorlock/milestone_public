import 'dart:async';

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/domain/repos/client_repo.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/custom_chip.dart';
import 'package:provider/provider.dart';

class ClientPicker extends StatefulWidget {
  const ClientPicker({super.key});

  @override
  State<ClientPicker> createState() => _ClientPickerState();
}

class _ClientPickerState extends State<ClientPicker> {
  final menuController = TextEditingController();
  String? _lastSyncedClientKey;
  bool _recoveryChecked = false;

  @override
  void dispose() {
    menuController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recoveryChecked) {
      return;
    }
    _recoveryChecked = true;

    final ownerUserId = _currentUserIdOrNull();
    if (ownerUserId == null) {
      return;
    }

    final currentRouteLocation = GoRouterState.of(context).uri.toString();
    final pendingRecovery = sl<ClientEditorRecoveryStore>()
        .readCommittedForTarget(
          ownerUserId: ownerUserId,
          targetLocation: currentRouteLocation,
        );
    if (pendingRecovery?.disposition !=
        ClientEditorRecoveryDisposition.selectCreatedClient) {
      return;
    }

    unawaited(
      _reconcileRecoveredClient(
        ownerUserId: pendingRecovery!.ownerUserId,
        clientId: pendingRecovery.clientId,
        operationId: pendingRecovery.operationId,
      ),
    );
  }

  Future<void> _reconcileRecoveredClient({
    required String ownerUserId,
    required String clientId,
    required String operationId,
  }) async {
    final controller = context.read<ProjectFormController>();
    final existingClient = controller.clients.where((client) {
      return client.id == clientId;
    }).firstOrNull;

    if (existingClient != null) {
      controller.selectClient(existingClient);
      await sl<ClientEditorRecoveryStore>().consume(
        ownerUserId: ownerUserId,
        operationId: operationId,
      );
      return;
    }

    final result = await sl<ClientRepo>().getClientById(clientId);
    final client = result.fold<Client?>((_) => null, (client) => client);
    if (client != null) {
      controller.selectClient(client);
      await sl<ClientEditorRecoveryStore>().consume(
        ownerUserId: ownerUserId,
        operationId: operationId,
      );
    }
  }

  String? _currentUserIdOrNull() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Exception {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectFormController>(
      builder: (_, controller, _) {
        final selectedClient = controller.selectedClient;
        final selectedClientKey = selectedClient == null
            ? null
            : '${selectedClient.id}:${selectedClient.name}';
        if (selectedClientKey != _lastSyncedClientKey) {
          _lastSyncedClientKey = selectedClientKey;
          menuController.text = selectedClient?.name ?? '';
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            final dropdownWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - 126) < 220
                ? 220.0
                : constraints.maxWidth - 126;

            final pickerHelperText = Text(
              "Can't find the client? Add Client",
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            );

            final dropdown = SizedBox(
              width: dropdownWidth,
              child: DropdownMenu<Client>(
                controller: menuController,
                width: dropdownWidth,
                initialSelection: selectedClient,
                hintText: 'Client',
                requestFocusOnTap: true,
                onSelected: (client) {
                  if (client == null) {
                    menuController.text = controller.selectedClient?.name ?? '';
                    return;
                  }

                  controller.selectClient(client);
                  menuController.text = client.name;
                },
                dropdownMenuEntries: controller.clients.map(
                  (client) {
                    return DropdownMenuEntry<Client>(
                      value: client,
                      label: client.name,
                    );
                  },
                ).toList(),
                enableSearch: false,
                enableFilter: true,
              ),
            );

            final addClientAction = CustomChip(
              label: 'Add Client',
              onTap: () async {
                // I'm intentionally using push here since we need results.
                // Using `go` would make that difficult and hacky to achieve.

                // TODO(Implementation): Use a dialog or bottom sheet instead
                //  of navigating to a new page.
                final result = await context.push<Client>(
                  AppRoutes.addClient,
                  extra: AddClientRouteSuccessMode.returnCreatedClient(
                    recoveryTargetLocation: GoRouterState.of(
                      context,
                    ).uri.toString(),
                  ),
                );
                if (result case Client()) {
                  controller.selectClient(result);
                  _lastSyncedClientKey = '${result.id}:${result.name}';
                  menuController.text = result.name;
                }
              },
            );

            return Column(
              crossAxisAlignment: .start,
              children: [
                if (compact)
                  Column(
                    crossAxisAlignment: .start,
                    spacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: .start,
                        mainAxisSize: .min,
                        spacing: 6,
                        children: [dropdown, pickerHelperText],
                      ),
                      addClientAction,
                    ],
                  )
                else
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(child: dropdown),
                      addClientAction,
                    ],
                  ),
                const Gap(8),
                if (!compact) pickerHelperText,
              ],
            );
          },
        );
      },
    );
  }
}
