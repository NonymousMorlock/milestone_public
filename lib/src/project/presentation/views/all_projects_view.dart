import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/outlined_back_button.dart';
import 'package:milestone/core/common/widgets/responsive_container.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';
import 'package:milestone/src/project/presentation/widgets/client_widget.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_bottom_half.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_top_half.dart';

class AllProjectsView extends StatefulWidget {
  const AllProjectsView({super.key});

  static const path = '/projects';

  @override
  State<AllProjectsView> createState() => _AllProjectsViewState();
}

class _AllProjectsViewState extends State<AllProjectsView> {
  final style = const ProjectTileStyle();

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(const $GetProjects());
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Projects',
      child: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (_, state) {
          if (state
              case ProjectError(
                title: final String title,
                message: final String message,
              )) {
            CoreUtils.showSnackBar(
              message: message,
              title: title,
              logLevel: LogLevel.error,
            );
          }
        },
        builder: (_, state) {
          return Scaffold(
            appBar: context.canPop()
                ? AppBar(leading: const OutlinedBackButton())
                : null,
            body: SafeArea(
              child: Center(
                child: StateRenderer(
                  loading: state is ProjectLoading,
                  child: Builder(
                    builder: (context) {
                      if (state case ProjectError(:final message)) {
                        return ErrorText(exception: Exception(message));
                      } else if (state case ProjectsLoaded(:final projects)) {
                        return ResponsiveContainer(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 32,
                                children: projects.map(
                                  (project) {
                                    return ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 300,
                                      ),
                                      // Adjust as needed
                                      child: ProjectTile(
                                        topHalf: ProjectTileTopHalf(project),
                                        bottomHalf:
                                            ProjectTileBottomHalf(project),
                                        clientAvatar: ClientWidget(
                                          clientName: project.clientName,
                                        ),
                                        style: style,
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
