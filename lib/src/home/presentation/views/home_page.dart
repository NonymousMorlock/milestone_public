import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/home/presentation/widgets/draggable_card.dart';
import 'package:milestone/src/home/presentation/widgets/home_body.dart';
import 'package:milestone/src/home/presentation/widgets/nav_drawer.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/views/add_project_view.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;

  final navNotifier = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    context.read<ProjectBloc>().add(const $GetProjects(limit: 5));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static const settingsWidth = 400.0;

  ProjectTileStyle style = const ProjectTileStyle();

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title: 'Milestone',
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              BlocConsumer<ProjectBloc, ProjectState>(
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
                  return StateRenderer(
                    loading: state is ProjectLoading,
                    builder: (_) {
                      if (state is ProjectsLoaded) {
                        if (state.projects.isEmpty) {
                          return Center(
                            child: Text(
                              'No projects found',
                              style: GoogleFonts.roboto(
                                fontSize: 24,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return HomeBody(projects: state.projects, style: style);
                      } else {
                        return const SizedBox();
                      }
                    },
                  );
                },
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 16),
                  child: FloatingActionButton.extended(
                    heroTag: 'add_project_FAB',
                    onPressed: () {
                      context.navigateTo(AddOrEditProjectView.path);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Project'),
                  ),
                ),
              ),
              NavDrawer(
                animationController: _animationController,
                navNotifier: navNotifier,
              ),
              Builder(
                builder: (context) {
                  return DraggableCard(
                    child: FloatingActionButton(
                      key: GlobalKey(),
                      onPressed: () {
                        if (_animationController.isDismissed) {
                          _animationController.forward();
                        } else {
                          _animationController.reverse();
                        }
                        navNotifier.value = false;
                      },
                      child: const Icon(Icons.menu),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
