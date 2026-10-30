import 'dart:async';

import 'package:flutter/material.dart';
import 'package:milestone/app/routing/milestone_editor_route_registry.dart';

class MilestoneEditorRouteSessionHost extends StatefulWidget {
  const MilestoneEditorRouteSessionHost({
    required this.registry,
    required this.sessionKey,
    required this.child,
    super.key,
  });

  final MilestoneEditorRouteRegistry registry;
  final String sessionKey;
  final Widget child;

  @override
  State<MilestoneEditorRouteSessionHost> createState() =>
      _MilestoneEditorRouteSessionHostState();
}

class _MilestoneEditorRouteSessionHostState
    extends State<MilestoneEditorRouteSessionHost> {
  @override
  void dispose() {
    unawaited(widget.registry.disposeSession(widget.sessionKey));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
