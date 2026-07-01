import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/home/presentation/utils/home_utils.dart';

class HomeTotalEarnedSection extends StatelessWidget {
  const HomeTotalEarnedSection({required this.onOpenProjects, super.key});

  final VoidCallback onOpenProjects;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return AppSectionCard(
      title: 'Earnings',
      subtitle:
          'Snapshot of the money tracked through your Milestone workspace.',
      child: StreamBuilder<double>(
        stream: HomeUtils.totalEarned,
        builder: (context, snapshot) {
          final totalEarned = snapshot.data ?? 0;
          return Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                totalEarned.currency,
                style: context.textTheme.displaySmall?.copyWith(
                  fontWeight: .w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Total earned across all tracked work so far.',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
