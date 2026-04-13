import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/presentation/adapter/client_cubit.dart';

class ClientWidget extends StatefulWidget {
  const ClientWidget({
    required this.clientName,
    required this.clientId,
    this.clientCubit,
    super.key,
  });

  final String clientName;
  final String clientId;

  /// TEST ONLY
  final ClientCubit? clientCubit;

  @override
  State<ClientWidget> createState() => _ClientWidgetState();
}

class _ClientWidgetState extends State<ClientWidget> {
  Client? _client;
  ClientCubit? _clientCubit;
  bool _ownsClientCubit = false;

  @override
  void initState() {
    super.initState();
    if (widget.clientCubit != null) {
      _clientCubit = widget.clientCubit;
      // I'm returning early because the injected cubit only exists in test
      // scenarios.
      return;
    }
    _clientCubit = sl<ClientCubit>();
    _ownsClientCubit = true;
    if (_clientCubit != null) {
      unawaited(_clientCubit!.getClientById(widget.clientId));
    }
  }

  @override
  void dispose() {
    if (_ownsClientCubit && _clientCubit != null) {
      unawaited(_clientCubit!.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO(Implement): Add a client details page and make this widget
    //  navigable to it.
    final scheme = context.colorScheme;
    final tokens = context.milestoneTheme;
    return SizedBox(
      width: 72,
      height: 72,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: .circle,
          color: scheme.surfaceContainerHighest,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: .circle,
              gradient: SweepGradient(
                colors: [
                  tokens.clientAvatarStart,
                  tokens.clientAvatarMiddle,
                  tokens.clientAvatarEnd,
                ],
              ),
            ),
            child: Center(
              child: _clientCubit == null
                  ? Text(
                      widget.clientName.initials,
                      textAlign: .center,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : BlocConsumer<ClientCubit, ClientState>(
                      bloc: _clientCubit,
                      listener: (_, state) {
                        if (state case ClientLoaded(:final client)) {
                          _client = client;
                        }
                      },
                      builder: (_, state) {
                        if (_client != null) {
                          return ClipOval(
                            child: Image.network(_client!.image!),
                          );
                        }

                        return Text(
                          widget.clientName.initials,
                          textAlign: .center,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimary,
                            letterSpacing: 1.5,
                            fontWeight: .w700,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
