import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/core/common/widgets/adaptive_base.dart';
import 'package:milestone/core/common/widgets/outlined_back_button.dart';
import 'package:milestone/core/common/widgets/responsive_container.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/res.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/project/presentation/app/adapter/project_bloc.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';
import 'package:milestone/src/project/presentation/views/add_project_view.dart';
import 'package:milestone/src/project/presentation/widgets/project_link_tile.dart';
import 'package:provider/provider.dart';

class ProjectDetailsView extends StatefulWidget {
  const ProjectDetailsView({required this.projectId, super.key});

  final String projectId;

  @override
  State<ProjectDetailsView> createState() => _ProjectDetailsViewState();
}

class _ProjectDetailsViewState extends State<ProjectDetailsView> {
  String? projectName;

  @override
  void initState() {
    super.initState();
    context.read<ProjectBloc>().add($GetProjectById(widget.projectId));
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveBase(
      title:
          projectName == null ? 'Project Details' : 'Projects | $projectName',
      child: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state case ProjectError(:final title, :final message)) {
            CoreUtils.showSnackBar(
              message: message,
              title: title,
              logLevel: LogLevel.error,
            );
          } else if (state case ProjectLoaded(:final project)) {
            context.read<ProjectFormController>().init(project);
            setState(() {
              projectName = project.projectName;
            });
          }
        },
        builder: (context, state) {
          final appBarActions = [
            IconButton(
              onPressed: () {
                if (state case ProjectLoaded(:final project)) {
                  context.go(
                    AddOrEditProjectView.path,
                    extra: project,
                  );
                }
              },
              icon: const Icon(Icons.drive_file_rename_outline),
            ),
          ];
          return Consumer<ProjectFormController>(
            builder: (context, controller, __) {
              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: context.canPop()
                    ? AppBar(
                        leading: const OutlinedBackButton(),
                        backgroundColor: Colors.transparent,
                        actions: appBarActions,
                      )
                    : AppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.transparent,
                        actions: appBarActions,
                      ),
                body: StateRenderer(
                  loading: state is ProjectLoading,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      SizedBox(
                        height: context.height * .4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: controller.imageController.text.isEmpty
                                  ? const AssetImage(Res.projectBanner1)
                                  : NetworkImage(
                                      controller.imageController.text,
                                    ) as ImageProvider,
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.7),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                bottom: 16,
                              ),
                              child: Text(
                                controller.nameController.text,
                                textAlign: TextAlign.center,
                                style: context.theme.textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ResponsiveContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SelectionArea(
                                child: ExpansionTile(
                                  title: const Text('Links'),
                                  collapsedBackgroundColor: Colours
                                      .lightThemePrimaryColour
                                      .withValues(alpha: .3),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: const BorderSide(
                                      color: Colours.lightThemePrimaryColour,
                                    ),
                                  ),
                                  textColor: Colors.white,
                                  collapsedTextColor: Colors.white,
                                  iconColor: Colors.white,
                                  collapsedIconColor: Colors.white,
                                  children: controller.linkControllers
                                      .mapIndexed((index, linkController) {
                                    return ProjectLinkTile(
                                      index: index,
                                      controller: linkController,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                floatingActionButton: controller.updateRequired
                    ? FloatingActionButton.extended(
                        onPressed: () {},
                        label: const Text('Save'),
                        icon: const Icon(Icons.save),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
