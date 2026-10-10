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

FutureOr<String?> _redirectProtectedClientRoute(
  BuildContext _,
  GoRouterState _,
) async {
  FlutterNativeSplash.remove();

  final snapshotUser = FirebaseAuth.instance.currentUser;
  if (snapshotUser != null) {
    if (!snapshotUser.emailVerified) {
      return '/verify-email';
    }
    return null;
  }

  final resolvedUser = await FirebaseAuth.instance.authStateChanges().first;
  if (resolvedUser == null || resolvedUser.displayName == null) {
    return SignInView.path;
  }

  return null;
}

String _clientEditorSessionKey(GoRouterState state) {
  return state.pageKey.value;
}

ClientEditorRouteSession _ensureClientEditorSession({
  required GoRouterState state,
  required ClientEditorRouteMode mode,
  AddClientRouteSuccessMode? addSuccessMode,
  EditClientRouteSuccessMode? editSuccessMode,
  String? clientId,
}) {
  final sessionKey = _clientEditorSessionKey(state);
  final ownerUserId = FirebaseAuth.instance.currentUser!.uid;
  final registry = sl<ClientEditorRouteRegistry>();
  final recoveryStore = sl<ClientEditorRecoveryStore>();

  return registry.ensureSession(
    sessionKey: sessionKey,
    create: () {
      final recoveryRecord = switch (mode) {
        ClientEditorRouteMode.add => recoveryStore.ensureAddDraftForRouteEntry(
          ownerUserId: ownerUserId,
          sessionKey: sessionKey,
          successMode:
              addSuccessMode ?? const AddClientRouteSuccessMode.goToClients(),
        ),
        ClientEditorRouteMode.edit => recoveryStore.ensureEditDraft(
          ownerUserId: ownerUserId,
          sessionKey: sessionKey,
          clientId: clientId!,
          successMode:
              editSuccessMode ??
              EditClientRouteSuccessMode.goToClientDetails(clientId: clientId),
        ),
      };

      return ClientEditorRouteSession(
        sessionKey: sessionKey,
        mode: mode,
        clientId: recoveryRecord.clientId,
        recoveryRecord: recoveryRecord,
        cubit: sl<ClientCubit>(),
        formController: ClientFormController(),
      );
    },
  );
}

Future<bool> _handleClientEditorExit(
  BuildContext _,
  GoRouterState state,
) async {
  final sessionKey = _clientEditorSessionKey(state);
  final registry = sl<ClientEditorRouteRegistry>();
  final recoveryStore = sl<ClientEditorRecoveryStore>();
  final session = registry.sessionFor(sessionKey);

  if (session == null) {
    return true;
  }

  if (FirebaseAuth.instance.currentUser == null) {
    if (session.isMutating) {
      registry.detachAwaitingMutationOutcome(sessionKey);
      return true;
    }

    if (session.recoveryRecord.status == ClientEditorRecoveryStatus.draft) {
      await recoveryStore.clearForSession(
        ownerUserId: session.recoveryRecord.ownerUserId,
        sessionKey: sessionKey,
      );
    }
    registry.releaseAfterAllowedExit(sessionKey);
    return true;
  }

  if (session.isMutating) {
    CoreUtils.showSnackBar(
      title: 'Client save in progress',
      message: 'Please wait for the client save to finish.',
      logLevel: LogLevel.warning,
    );
    return false;
  }

  if (session.recoveryRecord.status == ClientEditorRecoveryStatus.draft) {
    await recoveryStore.clearForSession(
      ownerUserId: session.recoveryRecord.ownerUserId,
      sessionKey: sessionKey,
    );
  }

  registry.releaseAfterAllowedExit(sessionKey);
  return true;
}

Widget _wrapClientEditorRoute({
  required GoRouterState state,
  required ClientEditorRouteSession session,
  required Widget child,
}) {
  final registry = sl<ClientEditorRouteRegistry>();

  return ClientEditorRouteSessionHost(
    registry: registry,
    sessionKey: _clientEditorSessionKey(state),
    child: Provider<ClientEditorRouteSession>.value(
      value: session,
      child: ChangeNotifierProvider<ClientFormController>.value(
        value: session.formController,
        child: BlocProvider<ClientCubit>.value(
          value: session.cubit,
          child: child,
        ),
      ),
    ),
  );
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
              path: AppRoutes.clients,
              redirect: _redirectProtectedClientRoute,
              pageBuilder: (_, state) {
                return _pageBuilder(
                  BlocProvider(
                    create: (_) => sl<ClientCubit>(),
                    child: const AllClientsView(),
                  ),
                  state: state,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.addClient,
              redirect: _redirectProtectedClientRoute,
              onExit: _handleClientEditorExit,
              pageBuilder: (context, state) {
                final successMode = switch (state.extra) {
                  AddClientRouteSuccessMode() =>
                    state.extra! as AddClientRouteSuccessMode,
                  _ => const AddClientRouteSuccessMode.goToClients(),
                };
                final session = _ensureClientEditorSession(
                  state: state,
                  mode: ClientEditorRouteMode.add,
                  addSuccessMode: successMode,
                );

                return _pageBuilder(
                  _wrapClientEditorRoute(
                    state: state,
                    session: session,
                    child: AddClientView(successMode: successMode),
                  ),
                  state: state,
                );
              },
            ),
            GoRoute(
              path: '${AppRoutes.clients}/:clientId/edit',
              redirect: _redirectProtectedClientRoute,
              onExit: _handleClientEditorExit,
              pageBuilder: (context, state) {
                final clientId = state.pathParameters['clientId']!;
                final successMode = switch (state.extra) {
                  EditClientRouteSuccessMode() =>
                    state.extra! as EditClientRouteSuccessMode,
                  _ => EditClientRouteSuccessMode.goToClientDetails(
                    clientId: clientId,
                  ),
                };
                final session = _ensureClientEditorSession(
                  state: state,
                  mode: ClientEditorRouteMode.edit,
                  editSuccessMode: successMode,
                  clientId: clientId,
                );

                return _pageBuilder(
                  _wrapClientEditorRoute(
                    state: state,
                    session: session,
                    child: EditClientView(
                      clientId: clientId,
                      successMode: successMode,
                    ),
                  ),
                  state: state,
                );
              },
            ),
            GoRoute(
              path: '${AppRoutes.clients}/:clientId',
              redirect: _redirectProtectedClientRoute,
              pageBuilder: (_, state) {
                return _pageBuilder(
                  BlocProvider(
                    create: (_) => sl<ClientCubit>(),
                    child: ClientDetailsView(
                      clientId: state.pathParameters['clientId']!,
                    ),
                  ),
                  state: state,
                );
              },
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
