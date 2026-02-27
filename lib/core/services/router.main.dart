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
    return '/';
  }
  return null;
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: rootNavigatorKey,
  routes: [
    ShellRoute(
      builder: (_, __, child) {
        return AppStateReactor(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
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
          path: ProfileView.path,
          pageBuilder: (context, state) => _pageBuilder(
            BlocProvider(
              create: (_) => sl<ProfileCubit>(),
              child: const ProfileView(),
            ),
            state: state,
          ),
          redirect: (_, __) {
            if (FirebaseAuth.instance.currentUser == null) {
              return SignInView.path;
            }
            return null;
          },
        ),
        GoRoute(
          path: '/verify-email',
          pageBuilder: (context, state) => _pageBuilder(
            AdaptiveBase(
              title: 'Verify Email',
              child: EmailVerificationScreen(
                // actionCodeSettings: ActionCodeSettings(
                //   url: 'https://milestone-e4ea6.firebaseapp.com',
                //   handleCodeInApp: true,
                //   androidInstallApp: true,
                //   androidMinimumVersion: '1',
                //   androidPackageName: 'co.akundadababalei.milestone',
                //   iOSBundleId: 'co.akundadababalei.milestone',
                // ),
                actions: [
                  EmailVerifiedAction(() => context.go('/')),
                  AuthCancelledAction((context) async {
                    final router = GoRouter.of(context);
                    await FirebaseUIAuth.signOut(context: context);
                    router.go('/');
                  }),
                  // authFailed,
                ],
              ),
            ),
            state: state,
          ),
        ),
        GoRoute(
          path: AddOrEditProjectView.path,
          pageBuilder: (context, state) {
            final child = MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<ClientCubit>()),
                BlocProvider(create: (_) => sl<ProjectBloc>()),
              ],
              child: AddOrEditProjectView(isEdit: state.extra is Project),
            );
            return _pageBuilder(
              switch (state.extra) {
                Project() => ChangeNotifierProvider.value(
                    value: ProjectFormController()
                      ..init(state.extra! as Project),
                    child: child,
                  ),
                _ => ChangeNotifierProvider(
                    create: (_) => ProjectFormController(),
                    child: child,
                  ),
              },
              state: state,
            );
          },
        ),
        GoRoute(
          path: AddClientView.path,
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
        GoRoute(
          path: AllProjectsView.path,
          pageBuilder: (context, state) => _pageBuilder(
            BlocProvider(
              create: (_) => sl<ProjectBloc>(),
              child: ChangeNotifierProvider(
                create: (_) => ExpandableCardController(),
                child: const AllProjectsView(),
              ),
            ),
            state: state,
          ),
          routes: [
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
            ),
            GoRoute(
              path: ':projectId/${AddMilestoneView.path}',
              pageBuilder: (context, state) => _pageBuilder(
                BlocProvider(
                  create: (_) => sl<MilestoneCubit>(),
                  child: const AddMilestoneView(),
                ),
                state: state,
              ),
            ),
          ],
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
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
      child: child,
    ),
  );
}
