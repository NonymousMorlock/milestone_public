import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:milestone/core/common/app/theme/cubit/theme_cubit.dart';
import 'package:milestone/core/enums/log_level.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/core/utils/core_utils.dart';
import 'package:milestone/src/home/presentation/widgets/nav_tile.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({
    required this.animationController,
    required this.navNotifier,
    super.key,
  });

  final AnimationController animationController;
  final ValueNotifier<bool> navNotifier;

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();

    _animation1 = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          widget.navNotifier.value = true;
        }
      });
    _animation2 =
        Tween<double>(begin: 0, end: .3).animate(widget.animationController)
          ..addListener(() {
            setState(() {});
          });
    _animation3 = Tween<double>(begin: .9, end: 1).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.fastLinearToSlowEaseIn,
        reverseCurve: Curves.ease,
      ),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaY: _animation1.value,
        sigmaX: _animation1.value,
      ),
      child: ValueListenableBuilder(
        valueListenable: widget.navNotifier,
        builder: (_, closed, __) {
          return Container(
            height: closed ? 0 : context.height,
            width: closed ? 0 : context.width,
            color: Colors.transparent,
            child: Center(
              child: Transform.scale(
                scale: _animation3.value,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: context.height * .05,
                    horizontal: context.width * .05,
                  ),
                  width: context.width * .9,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _animation2.value),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.black12,
                        radius: 35,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const Gap(20),
                      Column(
                        children: [
                          NavTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context.read<ThemeCubit>().toggle();
                            },
                          ),
                          NavTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About',
                            onTap: () {
                              HapticFeedback.mediumImpact();

                              () {}();
                            },
                          ),
                          NavTile(
                            icon: Icons.feedback_outlined,
                            title: 'Feedback',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              CoreUtils.showSnackBar(
                                logLevel: LogLevel.error,
                                message: 'An unexpected error occurred '
                                    'while trying to authenticate you.',
                                title: 'Error Getting Feedback',
                              );
                            },
                          ),
                          NavTile(
                            icon: Icons.find_in_page_outlined,
                            title: 'Privacy Policy',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              () {}();
                            },
                          ),
                        ],
                      ),
                    ],
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
