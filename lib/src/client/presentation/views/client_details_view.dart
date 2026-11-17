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
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/components/client_details/client_details_message_state_component.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:milestone/src/client/presentation/sections/client_details/client_details_header_section.dart';
import 'package:milestone/src/client/presentation/sections/client_details/client_details_projects_section.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';

class ClientDetailsView extends StatefulWidget {
  const ClientDetailsView({
    required this.clientId,
    super.key,
  });

  final String clientId;

  @override
  State<ClientDetailsView> createState() => _ClientDetailsViewState();
}

class _ClientDetailsViewState extends State<ClientDetailsView> {
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
            targetLocation: AppRoutes.clientDetails(widget.clientId),
          );
      if (pendingRecovery?.disposition ==
          ClientEditorRecoveryDisposition.refreshClientDetail) {
        _pendingRecoveryOperationId = pendingRecovery!.operationId;
        _pendingRecoveryOwnerUserId = pendingRecovery.ownerUserId;
      }
    }
    unawaited(context.read<ClientCubit>().getClientWorkspace(widget.clientId));
  }

  String? _currentUserIdOrNull() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } on Exception {
      return null;
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Delete client?'),
          content: const Text(
            'Delete this client relationship?\n\n'
            'Clients with linked projects cannot be removed until the work is '
            'moved or deleted first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: context.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await context.read<ClientCubit>().deleteClient(widget.clientId);
  }

  Future<void> _openEdit() async {
    final result = await context.push<bool>(
      AppRoutes.editClient(widget.clientId),
      extra: EditClientRouteSuccessMode.returnUpdatedFlag(
        recoveryTargetLocation: AppRoutes.clientDetails(widget.clientId),
      ),
    );
    if (!mounted || result != true) {
      return;
    }

    await context.read<ClientCubit>().getClientWorkspace(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Client Details',
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (context, state) async {
          if (state case ClientDeleted()) {
            context.go(AppRoutes.clients);
            CoreUtils.showSnackBar(
              title: 'Success',
              message: 'Client deleted successfully',
              logLevel: LogLevel.success,
            );
            return;
          }

          if (state case ClientWorkspaceLoaded(:final actionFailure)) {
            if (_pendingRecoveryOperationId != null &&
                _pendingRecoveryOwnerUserId != null) {
              await sl<ClientEditorRecoveryStore>().consume(
                ownerUserId: _pendingRecoveryOwnerUserId!,
                operationId: _pendingRecoveryOperationId!,
              );
              _pendingRecoveryOperationId = null;
              _pendingRecoveryOwnerUserId = null;
            }

            if (actionFailure != null) {
              CoreUtils.showSnackBar(
                title: actionFailure.title,
                message: actionFailure.message,
                logLevel: LogLevel.error,
              );
            }
            return;
          }

          if (state case ClientError(:final title, :final message)) {
            CoreUtils.showSnackBar(
              title: title,
              message: message,
              logLevel: LogLevel.error,
            );
          }
        },
        builder: (context, state) {
          final snapshot = switch (state) {
            ClientWorkspaceLoaded(:final snapshot) => snapshot,
            _ => null,
          };

          return AppPageScaffold(
            title: snapshot?.clientName ?? 'Client details',
            subtitle:
                'Projects, spend, and commercial context for '
                'this relationship.',
            actions: [
              FilledButton.icon(
                onPressed: switch (state) {
                  ClientWorkspaceLoaded(:final isMutationBusy)
                      when !isMutationBusy =>
                    _openEdit,
                  _ => null,
                },
                icon: const Icon(Icons.drive_file_rename_outline),
                label: const Text('Edit Client'),
              ),
              OutlinedButton.icon(
                onPressed: switch (state) {
                  ClientWorkspaceLoaded(:final isMutationBusy)
                      when !isMutationBusy =>
                    _confirmDelete,
                  _ => null,
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Client'),
              ),
            ],
            child: switch (state) {
              ClientWorkspaceLoading() => const StateRenderer(
                loading: true,
                child: SizedBox.shrink(),
              ),
              ClientWorkspaceLoaded(
                :final snapshot,
                :final projects,
                :final isRefreshing,
                :final actionFailure,
              ) =>
                Column(
                  crossAxisAlignment: .stretch,
                  spacing: 16,
                  children: [
                    if (isRefreshing) const LinearProgressIndicator(),
                    if (actionFailure != null)
                      AppSectionCard(
                        title: actionFailure.title,
                        subtitle: actionFailure.message,
                        child: const Text(
                          'Use the refreshed linked projects below to '
                          'resolve the conflict.',
                        ),
                      ),
                    ClientDetailsHeaderSection(snapshot: snapshot),
                    ClientDetailsProjectsSection(
                      projects: projects,
                      onOpenProject: (project) {
                        context.go('${AllProjectsView.path}/${project.id}');
                      },
                    ),
                  ],
                ),
              ClientError(statusCode: 'CLIENT_NOT_FOUND') =>
                ClientDetailsMessageStateComponent(
                  title: 'Client unavailable',
                  message: 'This client no longer exists.',
                  onBackToList: () => context.go(AppRoutes.clients),
                ),
              ClientError(:final message) => ClientDetailsMessageStateComponent(
                title: 'Unable to load client',
                message: message,
                onBackToList: () => context.go(AppRoutes.clients),
              ),
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }
}
