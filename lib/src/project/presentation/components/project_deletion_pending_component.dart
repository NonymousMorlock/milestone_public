import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';

class ProjectDeletionPendingComponent extends StatelessWidget {
  const ProjectDeletionPendingComponent({
    required this.projectName,
    required this.onRetryDelete,
    required this.onBackToProjects,
    super.key,
    this.isBusy = false,
  });

  final String projectName;
  final VoidCallback onRetryDelete;
  final VoidCallback onBackToProjects;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Project deletion in progress',
      subtitle: '$projectName is locked while deletion finishes.',
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          const Text(
            'Milestones, client totals, earned totals, and owned project media'
            ' are being cleaned up. Retry to continue finishing the delete'
            ' job, or return to the projects list.',
          ),
          const Gap(16),
          FilledButton.icon(
            onPressed: isBusy ? null : onRetryDelete,
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(isBusy ? 'Finishing delete...' : 'Finish Delete'),
          ),
          const Gap(12),
          OutlinedButton(
            onPressed: isBusy ? null : onBackToProjects,
            child: const Text('Back to Projects'),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Project Deletion Pending Component', group: 'Components')
Widget preview() {
  return ProjectDeletionPendingComponent(
    projectName: 'Example Project',
    onRetryDelete: () {},
    onBackToProjects: () {},
  );
}
