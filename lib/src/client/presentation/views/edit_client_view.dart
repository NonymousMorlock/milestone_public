import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/app/routing/client_editor_route_registry.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/add_client_form.dart';
import 'package:milestone/src/client/presentation/components/client_details/client_details_message_state_component.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';

class EditClientView extends StatefulWidget {
  const EditClientView({
    required this.clientId,
    required this.successMode,
    super.key,
  });

  final String clientId;
  final EditClientRouteSuccessMode successMode;

  @override
  State<EditClientView> createState() => _EditClientViewState();
}

class _EditClientViewState extends State<EditClientView> {
  String? _seededClientId;

  ClientEditorRouteSession get _session {
    return context.read<ClientEditorRouteSession>();
  }

  ClientFormController get _controller {
    return context.read<ClientFormController>();
  }

  ClientEditorRecoveryStore get _recoveryStore {
    return sl<ClientEditorRecoveryStore>();
  }

  ClientEditorRouteRegistry get _registry {
    return sl<ClientEditorRouteRegistry>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recoveryRecord = _session.recoveryRecord;
      if (recoveryRecord.status == ClientEditorRecoveryStatus.committed) {
        unawaited(_resolveCommittedEditRecovery(recoveryRecord));
        return;
      }
      unawaited(
        context.read<ClientCubit>().bootstrapClientEdit(widget.clientId),
      );
    });
  }

  Future<void> _handleBackNavigation() async {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.clientDetails(widget.clientId));
  }

  Future<void> _submit() async {
    final state = context.read<ClientCubit>().state;
    if (state case ClientEditLoaded(:final isSaving) when isSaving) {
      return;
    }
    if (!_controller.formKey.currentState!.validate() ||
        !_controller.updateRequired) {
      return;
    }

    await _recoveryStore.markSaving(
      ownerUserId: _session.recoveryRecord.ownerUserId,
      operationId: _session.recoveryRecord.operationId,
    );

    if (!mounted) return;
    await context.read<ClientCubit>().saveClientEdit(
      clientId: widget.clientId,
      updatedClient: _controller.compileUpdateData(),
    );

    if (!mounted) return;
    final postSaveState = context.read<ClientCubit>().state;
    if (postSaveState is ClientUpdated) {
      await _recoveryStore.markCommitted(
        ownerUserId: _session.recoveryRecord.ownerUserId,
        operationId: _session.recoveryRecord.operationId,
      );

      if (!mounted) {
        await _registry.disposeDetachedOutcomeSession(_session.sessionKey);
        return;
      }

      CoreUtils.showSnackBar(
        title: 'Success',
        message: 'Client updated successfully',
        logLevel: LogLevel.success,
      );

      switch (widget.successMode.kind) {
        case 'returnUpdatedFlag':
          await _recoveryStore.consume(
            ownerUserId: _session.recoveryRecord.ownerUserId,
            operationId: _session.recoveryRecord.operationId,
          );
          if (mounted) {
            context.pop(true);
          }
        case 'goToClientDetails':
          await _recoveryStore.consume(
            ownerUserId: _session.recoveryRecord.ownerUserId,
            operationId: _session.recoveryRecord.operationId,
          );
          if (mounted) {
            context.go(AppRoutes.clientDetails(widget.clientId));
          }
      }
      return;
    }

    await _recoveryStore.markDraft(
      ownerUserId: _session.recoveryRecord.ownerUserId,
      operationId: _session.recoveryRecord.operationId,
    );

    if (!mounted) {
      await _recoveryStore.clearForSession(
        ownerUserId: _session.recoveryRecord.ownerUserId,
        sessionKey: _session.sessionKey,
      );
      await _registry.disposeDetachedOutcomeSession(_session.sessionKey);
    }
  }

  Future<void> _resolveCommittedEditRecovery(
    ClientEditorRecoveryRecord record,
  ) async {
    if (!mounted) {
      return;
    }
    context.go(record.targetLocation);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Edit Client',
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (context, state) {
          if (state case ClientEditLoaded(
            :final client,
            :final actionFailure,
            :final isSaving,
          )) {
            if (_seededClientId != client.id) {
              _controller.init(client);
              _seededClientId = client.id;
            }
            if (actionFailure != null && !isSaving) {
              CoreUtils.showSnackBar(
                title: actionFailure.title,
                message: actionFailure.message,
                logLevel: LogLevel.error,
              );
            }
          } else if (state case ClientError(
            :final title,
            :final message,
          ) when _seededClientId == null) {
            CoreUtils.showSnackBar(
              title: title,
              message: message,
              logLevel: LogLevel.error,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: switch (state) {
                  ClientEditLoaded(:final isSaving) when isSaving => null,
                  _ => _handleBackNavigation,
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            body: SafeArea(
              child: AppPageScaffold(
                title: 'Edit Client',
                subtitle:
                    'Update the relationship identity without rewriting spend.',
                widthPolicy: AppPageWidthPolicy.form,
                child: switch (state) {
                  ClientLoading() when _seededClientId == null =>
                    const StateRenderer(
                      loading: true,
                      child: SizedBox.shrink(),
                    ),
                  ClientEditLoaded(:final isSaving) => AddClientForm(
                    onSubmit: _submit,
                    isSubmitting: isSaving,
                    submitLabel: 'Save Client',
                    allowTotalSpentEdit: false,
                  ),
                  ClientError(statusCode: 'CLIENT_NOT_FOUND')
                      when _seededClientId == null =>
                    ClientDetailsMessageStateComponent(
                      title: 'Client unavailable',
                      message: 'This client no longer exists.',
                      onBackToList: () => context.go(AppRoutes.clients),
                    ),
                  ClientError(:final message) when _seededClientId == null =>
                    ClientDetailsMessageStateComponent(
                      title: 'Unable to load client',
                      message: message,
                      onBackToList: _handleBackNavigation,
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
