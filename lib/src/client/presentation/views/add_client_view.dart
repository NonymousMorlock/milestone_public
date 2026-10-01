import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/app/routing/client_editor_recovery_store.dart';
import 'package:milestone/app/routing/client_editor_route_registry.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/add_client_form.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';

class AddClientView extends StatefulWidget {
  const AddClientView({
    required this.successMode,
    super.key,
  });

  static const path = '/add';

  final AddClientRouteSuccessMode successMode;

  @override
  State<AddClientView> createState() => _AddClientViewState();
}

class _AddClientViewState extends State<AddClientView> {
  ClientEditorRouteSession get _session {
    return context.read<ClientEditorRouteSession>();
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
        unawaited(_resolveCommittedAddRecovery(recoveryRecord));
      }
    });
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.clients);
  }

  Future<void> _submitClient() async {
    if (context.read<ClientCubit>().state is ClientLoading) {
      return;
    }

    final controller = context.read<ClientFormController>();
    if (!controller.formKey.currentState!.validate()) {
      return;
    }

    await _recoveryStore.markSaving(
      ownerUserId: _session.recoveryRecord.ownerUserId,
      operationId: _session.recoveryRecord.operationId,
    );
    if (!mounted) return;
    await context.read<ClientCubit>().addClient(
      controller.compileCreate(clientId: _session.recoveryRecord.clientId),
    );

    if (!mounted) return;
    final postSaveState = context.read<ClientCubit>().state;
    if (postSaveState case ClientAdded(:final client)) {
      await _recoveryStore.markCommitted(
        ownerUserId: _session.recoveryRecord.ownerUserId,
        operationId: _session.recoveryRecord.operationId,
      );

      if (!mounted) {
        await _registry.disposeDetachedOutcomeSession(_session.sessionKey);
        return;
      }

      CoreUtils.showSnackBar(
        logLevel: LogLevel.success,
        message: 'Client added successfully',
        title: 'Success',
      );

      switch (widget.successMode.kind) {
        case 'returnCreatedClient':
        case 'returnCreatedClientAndRefreshList':
          await _recoveryStore.consume(
            ownerUserId: _session.recoveryRecord.ownerUserId,
            operationId: _session.recoveryRecord.operationId,
          );
          if (mounted) {
            context.pop(client);
          }
        case 'goToClients':
          await _recoveryStore.consume(
            ownerUserId: _session.recoveryRecord.ownerUserId,
            operationId: _session.recoveryRecord.operationId,
          );
          if (mounted) {
            context.go(AppRoutes.clients);
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

  Future<void> _resolveCommittedAddRecovery(
    ClientEditorRecoveryRecord record,
  ) async {
    if (!mounted) {
      return;
    }

    switch (record.disposition) {
      case .selectCreatedClient:
        context.go(record.targetLocation);
      case .refreshClientList:
        context.go(AppRoutes.clients);
      case .refreshClientDetail:
        context.go(record.targetLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Add Client',
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (context, state) {
          if (state case ClientError(:final title, :final message)) {
            CoreUtils.showSnackBar(
              logLevel: LogLevel.error,
              message: message,
              title: title,
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is ClientLoading;
          return PopScope(
            canPop: !isSubmitting,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || isSubmitting) {
                return;
              }
              _handleBackNavigation();
            },
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: isSubmitting
                    ? null
                    : IconButton(
                        onPressed: _handleBackNavigation,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
              ),
              body: SafeArea(
                child: AppPageScaffold(
                  title: 'Add Client',
                  subtitle:
                      'Create the commercial relationship before '
                      'attaching work.',
                  widthPolicy: .form,
                  child: StateRenderer(
                    loading: state is ClientLoading,
                    child: AddClientForm(
                      isSubmitting: isSubmitting,
                      onSubmit: _submitClient,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
