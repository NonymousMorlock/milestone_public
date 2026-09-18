import 'package:flutter/material.dart';
import 'package:milestone/core/common/layout/app_section_card.dart';
import 'package:milestone/src/client/presentation/components/client_details/client_details_no_projects_component.dart';
import 'package:milestone/src/client/presentation/widgets/client_details/client_project_tile.dart';
import 'package:milestone/src/project/domain/entities/project.dart';

class ClientDetailsProjectsSection extends StatelessWidget {
  const ClientDetailsProjectsSection({
    required this.projects,
    required this.onOpenProject,
    super.key,
  });

  final List<Project> projects;
  final ValueChanged<Project> onOpenProject;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Linked projects',
      subtitle: 'Work attached to this relationship right now.',
      child: projects.isEmpty
          ? const ClientDetailsNoProjectsComponent()
          : Column(
              children: projects.map((project) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClientProjectTile(
                    project: project,
                    onTap: () => onOpenProject(project),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
