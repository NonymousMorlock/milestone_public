part of 'injection_container.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  await _initProfile();
  await _initTheme();
  await _initProject();
  await _initClient();
  await _initMilestone();
}

Future<void> _initProfile() async {
  sl
    ..registerFactory(() => ProfileCubit(updateProfileImage: sl()))
    ..registerLazySingleton(() => UpdateProfileImage(sl()))
    ..registerLazySingleton<ProfileRepo>(() => ProfileRepoImpl(sl()))
    ..registerLazySingleton<ProfileRemoteDataSrc>(
      () => ProfileRemoteDataSrcImpl(storage: sl(), auth: sl()),
    );
}

Future<void> _initTheme() async {
  final isDarkMode = await CacheHelper.instance.fetchThemeMode$isDark();
  sl.registerSingleton(ThemeCubit(isDarkMode: isDarkMode));
}

Future<void> _initProject() async {
  sl
    ..registerFactory(
      () => ProjectBloc(
        addProject: sl(),
        deleteProject: sl(),
        editProjectDetails: sl(),
        getProjectById: sl(),
        getProjects: sl(),
      ),
    )
    ..registerLazySingleton(() => AddProject(sl()))
    ..registerLazySingleton(() => DeleteProject(sl()))
    ..registerLazySingleton(() => EditProjectDetails(sl()))
    ..registerLazySingleton(() => GetProjectById(sl()))
    ..registerLazySingleton(() => GetProjects(sl()))
    ..registerLazySingleton<ProjectRepo>(() => ProjectRepoImpl(sl()))
    ..registerLazySingleton<ProjectRemoteDataSrc>(
      () => ProjectRemoteDataSrcImpl(
        firestore: sl(),
        storage: sl(),
        auth: sl(),
      ),
    )
    ..registerLazySingleton(() => FirebaseFirestore.instance)
    ..registerLazySingleton(() => FirebaseStorage.instance)
    ..registerLazySingleton(() => FirebaseAuth.instance);
}

Future<void> _initClient() async {
  sl
    ..registerFactory(
      () => ClientCubit(
        addClient: sl(),
        deleteClient: sl(),
        editClient: sl(),
        getClientProjects: sl(),
        getClientById: sl(),
        getClients: sl(),
      ),
    )
    ..registerLazySingleton(() => AddClient(sl()))
    ..registerLazySingleton(() => DeleteClient(sl()))
    ..registerLazySingleton(() => EditClient(sl()))
    ..registerLazySingleton(() => GetClientProjects(sl()))
    ..registerLazySingleton(() => GetClientById(sl()))
    ..registerLazySingleton(() => GetClients(sl()))
    ..registerLazySingleton<ClientRepo>(() => ClientRepoImpl(sl()))
    ..registerLazySingleton<ClientRemoteDataSrc>(
      () => ClientRemoteDataSrcImpl(
        firestore: sl(),
        storage: sl(),
        auth: sl(),
      ),
    );
}

Future<void> _initMilestone() async {
  sl
    ..registerFactory(
      () => MilestoneCubit(
        addMilestone: sl(),
        deleteMilestone: sl(),
        editMilestone: sl(),
        getMilestoneById: sl(),
        getMilestones: sl(),
      ),
    )
    ..registerLazySingleton(() => AddMilestone(sl()))
    ..registerLazySingleton(() => DeleteMilestone(sl()))
    ..registerLazySingleton(() => EditMilestone(sl()))
    ..registerLazySingleton(() => GetMilestoneById(sl()))
    ..registerLazySingleton(() => GetMilestones(sl()))
    ..registerLazySingleton<MilestoneRepo>(() => MilestoneRepoImpl(sl()))
    ..registerLazySingleton<MilestoneRemoteDataSrc>(
      () => MilestoneRemoteDataSrcImpl(
        firestore: sl(),
        auth: sl(),
        firebasePathProvider: sl(),
      ),
    )
    ..registerLazySingleton(
      () => FirebasePathProvider(firestore: sl(), auth: sl()),
    );
}
