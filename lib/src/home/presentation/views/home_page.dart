import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:milestone/core/common/layout/app_page_scaffold.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/home/presentation/widgets/home_body.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ProjectTileStyle style = const ProjectTileStyle();

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add(
      const GetProjectsEvent(limit: 5, excludePendingDeletion: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Home',
      child: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (_, state) {
          if (state case ProjectError(
            :final String title,
            :final String message,
          )) {
            CoreUtils.showSnackBar(
              message: message,
              title: title,
              logLevel: .error,
            );
          }
        },
        builder: (_, state) {
          return AppPageScaffold(
            title: 'Home',
            subtitle: 'Your freelancer control center.',
            child: StateRenderer(
              loading: state is ProjectLoading,
              child: switch (state) {
                ProjectsLoaded(:final projects) => HomeBody(
                  projects: projects,
                  style: style,
                ),
                ProjectError(:final message) => HomeBody(
                  projects: const [],
                  style: style,
                  errorMessage: message,
                ),
                _ => HomeBody(
                  projects: const [],
                  style: style,
                ),
              },
            ),
          );
        },
      ),
    );
  }
}
