import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/res/res.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/widgets/project_image_title_glass_blob.dart';

class ProjectTileTopHalf extends StatelessWidget {
  ProjectTileTopHalf(
    this.project, {
    dynamic identifier,
    this.expandable = false,
    this.navigateOnTap = true,
    this.onTap,
    this.margin,
    super.key,
  }) : identifier = identifier ?? project.id;

  final dynamic identifier;
  final Project project;
  final VoidCallback? onTap;
  final bool expandable;
  final bool navigateOnTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.milestoneTheme;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          onTap: () {
            if (navigateOnTap) {
              context.go(
                '/projects/${project.id}',
                extra: project.projectName,
              );
            }
            onTap?.call();
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (project.image != null && project.image!.isNotEmpty)
                    Image.network(
                      project.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return Image.asset(
                          Res.projectBanner1,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  else
                    Image.asset(
                      Res.projectBanner1,
                      fit: BoxFit.cover,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          tokens.imageScrim.withValues(alpha: .16),
                          tokens.imageScrim.withValues(alpha: .8),
                        ],
                        stops: const [0, .55, 1],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-.9, 1.1),
                        radius: 1.15,
                        colors: [
                          tokens.imageScrim.withValues(alpha: .7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ProjectImageTitleGlassBlob(
                        title: project.projectName,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
