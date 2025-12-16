import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:milestone/core/common/widgets/responsive_container.dart';
import 'package:milestone/core/common/widgets/state_renderer.dart';
import 'package:milestone/core/common/widgets/text_placeholder.dart';
import 'package:milestone/core/enums/environment.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/extensions/double_extensions.dart';
import 'package:milestone/core/res/res.dart';
import 'package:milestone/core/res/styles/colours.dart';
import 'package:milestone/core/utils/constants/network_contants.dart';
import 'package:milestone/src/home/presentation/utils/home_utils.dart';
import 'package:milestone/src/profile/presentation/views/profile_view.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/presentation/views/all_projects_view.dart';
import 'package:milestone/src/project/presentation/widgets/boxy/project_tile_style.dart';
import 'package:milestone/src/project/presentation/widgets/client_widget.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_bottom_half.dart';
import 'package:milestone/src/project/presentation/widgets/project_tile_top_half.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({
    required this.projects,
    required this.style,
    super.key,
  });

  final List<Project> projects;
  final ProjectTileStyle style;

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  double? totalEarned;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              collapsedHeight: kToolbarHeight + 50,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    // linear gradient from any of the Colours above
                    gradient: const LinearGradient(
                      colors: [
                        Colours.lightThemePrimaryColour,
                        Colours.lightThemePrimaryTint,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(Res.flag, width: 50, height: 50),
                        Text(
                          'Milestone',
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colours.lightThemeWhiteColour,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ).copyWith(bottom: 16),
                centerTitle: true,
                title: StreamBuilder(
                  stream: HomeUtils.totalEarned,
                  builder: (context, snapshot) {
                    return StateRenderer(
                      loading:
                          snapshot.connectionState == ConnectionState.waiting &&
                              totalEarned != null,
                      child: Builder(
                        builder: (_) {
                          if (snapshot.hasData || totalEarned != null) {
                            final data = snapshot.data ?? totalEarned!;
                            return FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Text(
                                'Total Earned: ${data.currency}',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    );
                  },
                ),
              ),
              leadingWidth: double.maxFinite,
              leading: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.navigateTo(ProfileView.path),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                              user?.photoURL ?? NetworkConstants.defaultAvatar,
                            ),
                          ),
                          const Gap(8),
                          StateRenderer(
                            loading: snapshot.connectionState ==
                                ConnectionState.waiting,
                            loadingWidget: const TextPlaceholder(width: 100),
                            child: Text(
                              user?.displayName ?? 'Unknown User',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if ((isMobile
                    ? widget.projects.length > 5
                    : widget.projects.length > 10) ||
                context.environment == Environment.development) ...[
              const SliverToBoxAdapter(child: Gap(16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.navigateTo(AllProjectsView.path);
                      },
                      child: const Text('View All'),
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: ResponsiveContainer(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 32,
                    children: widget.projects.take(isMobile ? 5 : 10).map(
                      (project) {
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          // Adjust as needed
                          child: ProjectTile(
                            topHalf: ProjectTileTopHalf(project),
                            bottomHalf: ProjectTileBottomHalf(project),
                            clientAvatar: ClientWidget(
                              clientName: project.clientName,
                            ),
                            style: widget.style,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
