import 'package:flutter/material.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ClientProjectTile extends StatelessWidget {
  const ClientProjectTile({
    required this.project,
    required this.onTap,
    super.key,
  });

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        title: Text(
          project.projectName,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${project.totalPaid.currency} paid of ${project.budget.currency}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
