import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/components/all_clients/all_clients_body_component.dart';
import 'package:milestone/src/client/presentation/components/all_clients/all_clients_empty_state_component.dart';
import 'package:milestone/src/client/presentation/components/all_clients/all_clients_message_state_component.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';

class AllClientsView extends StatefulWidget {
  const AllClientsView({super.key});

  static const String path = AppRoutes.clients;

  @override
  State<AllClientsView> createState() => _AllClientsViewState();
}

class _AllClientsViewState extends State<AllClientsView> {
  String? _pendingRecoveryOperationId;
  String? _pendingRecoveryOwnerUserId;

  @override
  void initState() {
    super.initState();
    final ownerUserId = _currentUserIdOrNull();
    if (ownerUserId != null) {
      final pendingRecovery = sl<ClientEditorRecoveryStore>()
          .readCommittedForTarget(
            ownerUserId: ownerUserId,
            targetLocation: AppRoutes.clients,
          );
      if (pendingRecovery?.disposition ==
          ClientEditorRecoveryDisposition.refreshClientList) {
        _pendingRecoveryOperationId = pendingRecovery!.operationId;
        _pendingRecoveryOwnerUserId = pendingRecovery.ownerUserId;
      }
    }
    unawaited(context.read<ClientCubit>().getClientWorkspaceList());
  }

  String? _currentUserIdOrNull() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Exception {
      return null;
    }
  }

  Future<void> _openAddClient() async {
    final result = await context.push<Client>(
      AppRoutes.addClient,
      extra:
          const AddClientRouteSuccessMode.returnCreatedClientAndRefreshList(),
    );
    if (!mounted || result == null) {
      return;
    }

    await context.read<ClientCubit>().getClientWorkspaceList();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Clients',
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (context, state) async {
          if (state case ClientError(:final title, :final message)) {
            CoreUtils.showSnackBar(
              title: title,
              message: message,
              logLevel: LogLevel.error,
            );
          } else if (state is ClientWorkspaceListLoaded &&
              _pendingRecoveryOperationId != null &&
              _pendingRecoveryOwnerUserId != null) {
            await sl<ClientEditorRecoveryStore>().consume(
              ownerUserId: _pendingRecoveryOwnerUserId!,
              operationId: _pendingRecoveryOperationId!,
            );
            _pendingRecoveryOperationId = null;
            _pendingRecoveryOwnerUserId = null;
          }
        },
        builder: (context, state) {
          return AppPageScaffold(
            title: 'Clients',
            subtitle:
                'Track who the work is for and what each '
                'relationship is worth.',
            actions: [
              FilledButton.icon(
                onPressed: _openAddClient,
                icon: const Icon(Icons.add),
                label: const Text('Add Client'),
              ),
            ],
            child: AppSectionCard(
              title: 'Relationship library',
              subtitle: 'Current clients, linked work, and spend context.',
              child: StateRenderer(
                loading: state is ClientWorkspaceListLoading,
                builder: (context) {
                  if (state case ClientError(:final message)) {
                    return AllClientsMessageStateComponent(
                      title: 'Unable to load clients',
                      message: message,
                    );
                  }

                  if (state case ClientWorkspaceListLoaded(:final summaries)) {
                    if (summaries.isEmpty) {
                      return AllClientsEmptyStateComponent(
                        onAddClient: _openAddClient,
                      );
                    }

                    return AllClientsBodyComponent(
                      summaries: summaries,
                      onOpenClient: (summary) {
                        context.go(AppRoutes.clientDetails(summary.clientId));
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
