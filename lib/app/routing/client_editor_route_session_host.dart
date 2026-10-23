import 'dart:async';

import 'package:flutter/material.dart';
import 'package:milestone/app/routing/client_editor_route_registry.dart';

class ClientEditorRouteSessionHost extends StatefulWidget {
  const ClientEditorRouteSessionHost({
    required this.registry,
    required this.sessionKey,
    required this.child,
    super.key,
  });

  final ClientEditorRouteRegistry registry;
  final String sessionKey;
  final Widget child;

  @override
  State<ClientEditorRouteSessionHost> createState() =>
      _ClientEditorRouteSessionHostState();
}

class _ClientEditorRouteSessionHostState
    extends State<ClientEditorRouteSessionHost> {
  @override
  void dispose() {
    unawaited(widget.registry.handleRouteHostDispose(widget.sessionKey));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
