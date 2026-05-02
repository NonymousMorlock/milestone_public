import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/app/routing/app_routes.dart';
import 'package:milestone/core/common/layout/app_layout.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/client/presentation/add_client_form.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';

class AddClientView extends StatefulWidget {
  const AddClientView({super.key});

  static const path = '/add';

  @override
  State<AddClientView> createState() => _AddClientViewState();
}

class _AddClientViewState extends State<AddClientView> {
  bool _submitLocked = false;

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.initial);
  }

  void _submitClient() {
    if (_submitLocked) {
      return;
    }

    final controller = context.read<ClientFormController>();
    if (!controller.formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitLocked = true;
    });
    unawaited(context.read<ClientCubit>().addClient(controller.compile()));
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Add Client',
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (context, state) {
          if (state is ClientError) {
            if (_submitLocked) {
              setState(() {
                _submitLocked = false;
              });
            }
            CoreUtils.showSnackBar(
              logLevel: LogLevel.error,
              message: state.message,
              title: state.title,
            );
          } else if (state is ClientAdded) {
            CoreUtils.showSnackBar(
              logLevel: LogLevel.success,
              message: 'Client added successfully',
              title: 'Success',
            );
            context.pop(state.client);
          }
        },
        builder: (context, state) {
          final isSubmitting = _submitLocked || state is ClientLoading;
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
                      'Create the commercial relationship '
                      'before attaching work.',
                  widthPolicy: AppPageWidthPolicy.form,
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
