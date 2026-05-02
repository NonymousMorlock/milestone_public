part of 'router.dart';

// final authFailed = AuthStateChangeAction<AuthFailed>((context, state) async {
//   final exception = state.exception;
//   // if (kIsWeb &&
//   //     (defaultTargetPlatform != TargetPlatform.iOS &&
//   //         defaultTargetPlatform != TargetPlatform.android)) {
//   //   NativeDialog.alert(
//   //     exception is FirebaseException
//   //         ? (exception.message ?? 'Unknown Error Occurred')
//   //         : exception.toString(),
//   //   );
//   //   return;
//   // }
//   await CoreUtils.showErrorDialog(
//     context,
//     title: exception is FirebaseException ? exception.code :
//     'Error Occurred',
//     content: exception is FirebaseException
//         ? (exception.message ?? 'Unknown Error Occurred')
//         : exception.toString(),
//   );
// });

String? redirectToRoot(BuildContext context, GoRouterState state) {
  if (FirebaseAuth.instance.currentUser != null) {
    return AppRoutes.initial;
  }
  return null;
}

String _milestoneEditorSessionKey(GoRouterState state) {
  return state.pageKey.value;
}

MilestoneEditorRouteSession _ensureMilestoneEditorSession({
  required GoRouterState state,
  required String projectId,
  required bool isEdit,
  String? milestoneId,
}) {
  final sessionKey = _milestoneEditorSessionKey(state);
  final registry = sl<MilestoneEditorRouteRegistry>();

  return registry.ensureSession(
    sessionKey: sessionKey,
    create: () {
      return MilestoneEditorRouteSession(
        sessionKey: sessionKey,
        projectId: projectId,
        isEdit: isEdit,
        milestoneId: milestoneId,
        cubit: sl<MilestoneCubit>(),
        formController: MilestoneFormController(),
      );
    },
  );
}

FutureOr<bool> _handleMilestoneEditorExit(
  BuildContext _,
  GoRouterState state,
) {
  final sessionKey = _milestoneEditorSessionKey(state);
  final registry = sl<MilestoneEditorRouteRegistry>();
  final session = registry.sessionFor(sessionKey);

  if (session == null) {
    return true;
  }

  if (FirebaseAuth.instance.currentUser == null) {
    registry.releaseAfterAllowedExit(sessionKey);
    return true;
  }

  if (session.cubit.state.isMutating) {
    CoreUtils.showSnackBar(
      title: 'Milestone save in progress',
      message: 'Please wait for the milestone save to finish.',
      logLevel: LogLevel.warning,
    );
    return false;
  }

  registry.releaseAfterAllowedExit(sessionKey);
  return true;
}

Widget _wrapMilestoneEditorRoute({
  required GoRouterState state,
  required MilestoneEditorRouteSession session,
  required Widget child,
}) {
  final registry = sl<MilestoneEditorRouteRegistry>();

  return MilestoneEditorRouteSessionHost(
    registry: registry,
    sessionKey: _milestoneEditorSessionKey(state),
    child: ChangeNotifierProvider<MilestoneFormController>.value(
      value: session.formController,
      child: BlocProvider<MilestoneCubit>.value(
        value: session.cubit,
        child: child,
      ),
    ),
  );
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final stateReactorShellNavigatorKey = GlobalKey<NavigatorState>();
final appShellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: stateReactorShellNavigatorKey,
      builder: (_, _, child) {
        return AppStateReactor(child: child);
      },
      routes: [
        ShellRoute(
          navigatorKey: appShellNavigatorKey,
          builder: (context, state, child) {
            return AdaptiveAppShell(
              location: state.uri.toString(),
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: AppRoutes.initial,
              redirect: (context, state) async {
                FlutterNativeSplash.remove();
                var user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  user = await FirebaseAuth.instance.authStateChanges().first;
                  if (user == null || user.displayName == null) {
                    return SignInView.path;
                  }
                } else if (!user.emailVerified) {
                  return '/verify-email';
                }
                return null;
              },
              pageBuilder: (context, state) {
                FlutterNativeSplash.remove();
                return _pageBuilder(
                  BlocProvider(
                    create: (_) => sl<ProjectBloc>(),
                    child: const HomePage(),
                  ),
                  state: state,
                );
              },
            ),
            GoRoute(
              path: AllProjectsView.path,
              pageBuilder: (context, state) {
                return _pageBuilder(
                  BlocProvider(
                    create: (_) => sl<ProjectBloc>(),
                    child: const AllProjectsView(),
                  ),
                  state: state,
                );
              },
              routes: [
                GoRoute(
                  path: AddOrEditProjectView.addPath.normalisedNestedPath,
                  pageBuilder: (context, state) {
                    return _pageBuilder(
                      ChangeNotifierProvider(
                        create: (_) => ProjectFormController(),
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider(create: (_) => sl<ClientCubit>()),
                            BlocProvider(create: (_) => sl<ProjectBloc>()),
                          ],
                          child: AddOrEditProjectView(isEdit: false),
                        ),
                      ),
                      state: state,
                    );
                  },
                ),
                GoRoute(
                  path: ':projectId',
                  pageBuilder: (context, state) {
                    return _pageBuilder(
                      ChangeNotifierProvider(
                        create: (_) => ProjectFormController(),
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider(create: (_) => sl<ProjectBloc>()),
                            BlocProvider(create: (_) => sl<MilestoneCubit>()),
                          ],
                          child: ProjectDetailsView(
                            projectId: state.pathParameters['projectId']!,
                          ),
                        ),
                      ),
                      state: state,
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      pageBuilder: (context, state) {
                        final seedProject = switch (state.extra) {
                          Project() => state.extra! as Project,
                          _ => null,
                        };
                        return _pageBuilder(
                          ChangeNotifierProvider(
                            create: (_) => ProjectFormController(),
                            child: MultiBlocProvider(
                              providers: [
                                BlocProvider(create: (_) => sl<ClientCubit>()),
                                BlocProvider(create: (_) => sl<ProjectBloc>()),
                              ],
                              child: AddOrEditProjectView(
                                isEdit: true,
                                projectId: state.pathParameters['projectId'],
                                seedProject: seedProject,
                              ),
                            ),
                          ),
                          state: state,
                        );
                      },
                    ),
                    GoRoute(
                      // TODO(Implement): Add a dedicated milestone list page
                      path: 'milestones',
                      pageBuilder: (_, state) {
                        return _pageBuilder(
                          const AdaptiveBase(
                            title: 'Milestones',
                            child: Center(
                              child: Text('Milestone management coming soon!'),
                            ),
                          ),
                          state: state,
                        );
                      },
                      routes: [
                        GoRoute(
                          path: AddOrEditMilestoneView
                              .addPath
                              .normalisedNestedPath,
                          onExit: _handleMilestoneEditorExit,
                          pageBuilder: (context, state) {
                            final projectId =
                                state.pathParameters['projectId']!;
                            final session = _ensureMilestoneEditorSession(
                              state: state,
                              projectId: projectId,
                              isEdit: false,
                            );
                            return _pageBuilder(
                              _wrapMilestoneEditorRoute(
                                state: state,
                                session: session,
                                child: BlocProvider(
                                  create: (_) => sl<ProjectBloc>(),
                                  child: AddOrEditMilestoneView.add(
                                    projectId: projectId,
                                  ),
                                ),
                              ),
                              state: state,
                            );
                          },
                        ),
                        // TODO(Implement): Add a dedicated milestone details
                        //  page
                        GoRoute(
                          path: ':milestoneId',
                          pageBuilder: (_, state) {
                            return _pageBuilder(
                              const AdaptiveBase(
                                title: 'Milestones',
                                child: Center(
                                  child: Text(
                                    'Milestone management coming soon!',
                                  ),
                                ),
                              ),
                              state: state,
                            );
                          },
                          routes: [
                            GoRoute(
                              path: AddOrEditMilestoneView
                                  .editPath
                                  .normalisedNestedPath,
                              onExit: _handleMilestoneEditorExit,
                              pageBuilder: (context, state) {
                                final seedMilestone = switch (state.extra) {
                                  Milestone() => state.extra! as Milestone,
                                  _ => null,
                                };
                                final session = _ensureMilestoneEditorSession(
                                  state: state,
                                  projectId: state.pathParameters['projectId']!,
                                  milestoneId:
                                      state.pathParameters['milestoneId'],
                                  isEdit: true,
                                );
                                return _pageBuilder(
                                  _wrapMilestoneEditorRoute(
                                    state: state,
                                    session: session,
                                    child: BlocProvider(
                                      create: (_) => sl<ProjectBloc>(),
                                      child: AddOrEditMilestoneView.edit(
                                        projectId:
                                            state.pathParameters['projectId']!,
                                        milestoneId:
                                            state.pathParameters['milestoneId'],
                                        seedMilestone: seedMilestone,
                                      ),
                                    ),
                                  ),
                                  state: state,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              // TODO(Implement): Add a dedicated clients list page
              path: '/clients',
              pageBuilder: (_, state) {
                return _pageBuilder(
                  const AdaptiveBase(
                    title: 'Clients',
                    child: Center(
                      child: Text('Client management coming soon!'),
                    ),
                  ),
                  state: state,
                );
              },
              routes: [
                GoRoute(
                  path: AddClientView.path.normalisedNestedPath,
                  pageBuilder: (context, state) => _pageBuilder(
                    ChangeNotifierProvider(
                      create: (_) => ClientFormController(),
                      child: BlocProvider(
                        create: (_) => sl<ClientCubit>(),
                        child: const AddClientView(),
                      ),
                    ),
                    state: state,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: ProfileView.path,
          pageBuilder: (context, state) => _pageBuilder(
            BlocProvider(
              create: (_) => sl<ProfileCubit>(),
              child: const ProfileView(),
            ),
            state: state,
          ),
          redirect: (_, _) {
            if (FirebaseAuth.instance.currentUser == null) {
              return SignInView.path;
            }
            return null;
          },
        ),
        GoRoute(
          path: SignInView.path,
          redirect: redirectToRoot,
          pageBuilder: (context, goState) => _pageBuilder(
            const AdaptiveBase(title: 'Auth', child: SignInView()),
            state: goState,
          ),
        ),
        GoRoute(
          path: '/register',
          redirect: redirectToRoot,
          pageBuilder: (context, goState) => _pageBuilder(
            const AdaptiveBase(title: 'Auth', child: RegisterView()),
            state: goState,
          ),
        ),
        GoRoute(
          path: '/verify-email',
          pageBuilder: (context, state) => _pageBuilder(
            AdaptiveBase(
              title: 'Verify Email',
              child: EmailVerificationScreen(
                actions: [
                  EmailVerifiedAction(
                    () => context.go(AppRoutes.initial),
                  ),
                  AuthCancelledAction((context) async {
                    final router = GoRouter.of(context);
                    await FirebaseUIAuth.signOut(context: context);
                    router.go(AppRoutes.initial);
                  }),
                ],
              ),
            ),
            state: state,
          ),
        ),
      ],
    ),
  ],
);

Page<dynamic> _pageBuilder(Widget page, {required GoRouterState state}) {
  FlutterNativeSplash.remove();
  return CustomTransitionPage(
    key: state.pageKey,
    child: page,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
      child: child,
    ),
  );
}
