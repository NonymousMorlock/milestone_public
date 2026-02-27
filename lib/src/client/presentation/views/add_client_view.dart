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
import 'package:milestone/src/client/presentation/add_client_form.dart';

class AddClientView extends StatelessWidget {
  const AddClientView({super.key});

  static const path = '/add-client';

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Add Client',
      child: BlocConsumer<ClientCubit, ClientState>(
        listener: (context, state) {
          if (state is ClientError) {
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
          return Scaffold(
            appBar: (kIsWasm || kIsWeb)
                ? null
                : AppBar(
                    title: const Text('Add Client'),
                  ),
            body: ResponsiveContainer.sm(
              child: StateRenderer(
                loading: state is ClientLoading,
                child: const AddClientForm(),
              ),
            ),
          );
        },
      ),
    );
  }
}
