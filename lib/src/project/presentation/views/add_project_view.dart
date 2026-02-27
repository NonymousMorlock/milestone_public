import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/responsive_container.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/widgets/add_project_form.dart';

class AddOrEditProjectView extends StatefulWidget {
  const AddOrEditProjectView({required this.isEdit, super.key});

  final bool isEdit;

  static const path = '/add-project';

  @override
  State<AddOrEditProjectView> createState() => _AddOrEditProjectViewState();
}

class _AddOrEditProjectViewState extends State<AddOrEditProjectView> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<ClientCubit>().getClients());
  }

  @override
  Widget build(BuildContext context) {
    final titleText = switch (widget.isEdit) {
      true => 'Edit Project',
      _ => 'Add Project',
    };
    return AdaptiveBase(
      title: titleText,
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (_, state) {
          if (state case ClientsLoaded() when state.clients.isNotEmpty) {
            context.read<ProjectFormController>().setClients(state.clients);
          } else if (state is ClientError) {
            unawaited(
              CoreUtils.showSnackBar(
                logLevel: LogLevel.error,
                message: state.message,
                title: state.title,
              ),
            );
            context.go('/');
          }
        },
        builder: (_, clientAdapterState) {
          return BlocConsumer<ProjectBloc, ProjectState>(
            listener: (_, state) async {
              if (state is ProjectAdded) {
                context.go('/');
                await CoreUtils.showSnackBar(
                  logLevel: LogLevel.success,
                  title: 'Success',
                  message: 'Project added successfully',
                );
              } else if (state is ProjectError) {
                await CoreUtils.showSnackBar(
                  logLevel: LogLevel.error,
                  message: state.message,
                  title: state.title,
                );
              }
            },
            builder: (_, projectAdapterState) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (_, __) {
                  // I'm doing this because I want the home page to be reloaded
                  // this way the new project will be displayed in the list.
                  context.go('/');
                },
                child: Scaffold(
                  appBar: kIsWasm || kIsWeb
                      ? null
                      : AppBar(
                          title: Text(titleText),
                        ),
                  body: SafeArea(
                    child: ResponsiveContainer.sm(
                      child: StateRenderer(
                        loading: clientAdapterState is ClientLoading ||
                            projectAdapterState is ProjectLoading,
                        // a form that collects the project details, and for
                        // client, it uses a dropdown to select the client, and
                        // the dropdown will return the client.id, and for
                        // userId we can use
                        // FirebaseAuth.instance.currentUser.uid
                        child: AddOrEditProjectForm(isEdit: widget.isEdit),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
