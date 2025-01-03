import 'package:flutter/material.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';

class AddMilestoneView extends StatelessWidget {
  const AddMilestoneView({super.key});

  static const path = 'add-milestone';

  @override
  Widget build(BuildContext context) {
    return const AdaptiveBase(title: 'Add Milestone', child: Placeholder());
  }
}
