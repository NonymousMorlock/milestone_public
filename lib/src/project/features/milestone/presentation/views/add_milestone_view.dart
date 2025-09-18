import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/features/milestone/presentation/adapter/milestone_cubit.dart';

class AddMilestoneView extends StatelessWidget {
  const AddMilestoneView({super.key});

  static const path = 'add-milestone';

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Add Milestone',
      child: BlocConsumer<MilestoneCubit, MilestoneState>(
        listener: (_, state) {
          if (state case MilestoneError(:final message, :final title)) {
            CoreUtils.showSnackBar(
              message: message,
              title: title,
              logLevel: LogLevel.error,
            );
          }
        },
        builder: (_, state) {
          return const Placeholder();
        },
      ),
    );
  }
}
