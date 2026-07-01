import 'package:equatable/equatable.dart';
import 'package:milestone/src/project/domain/entities/u_r_l.dart';

class Project extends Equatable {
  const Project({
    required this.id,
    required this.userId,
    required this.projectName,
    required this.clientName,
    required this.shortDescription,
    required this.budget,
    required this.projectType,
    required this.totalPaid,
    required this.numberOfMilestonesSoFar,
    required this.startDate,
    required this.clientId,
    this.longDescription,
    this.imageIsFile = false,
    this.isFixed = true,
    this.isOneTime = true,
    this.image,
    this.deadline,
    this.urls = const [],
    this.images = const [],
    this.imagesModeRegistry = const [],
    this.notes = const [],
    this.tools = const [],
    this.endDate,
    this.lastUpdated,
    this.deletionRequestedAt,
    this.featureImageStoragePath,
    this.ownedStoragePaths = const [],
  }) : assert(
         images.length == imagesModeRegistry.length,
         'if images is not empty, then you must register which of them are '
         'files and which are not',
       );

  Project.empty()
    : this(
        id: 'Test String',
        userId: 'Test String',
        projectName: 'Test String',
        projectType: 'Test String',
        clientName: 'Test String',
        shortDescription: 'Test String',
        urls: [],
        budget: 1,
        totalPaid: 1,
        images: [],
        notes: [],
        tools: [],
        numberOfMilestonesSoFar: 1,
        clientId: 'Test String',
        startDate: DateTime.now(),
        deadline: DateTime.now(),
        endDate: DateTime.now(),
      );

  @override
  String toString() {
    return 'Project{id: $id, userId: $userId, projectName: $projectName, '
        'clientName: $clientName, shortDescription: $shortDescription, '
        'longDescription: $longDescription, imageIsFile: $imageIsFile, '
        'notes: $notes, urls: $urls, budget: $budget, isFixed: $isFixed, '
        'isOneTime: $isOneTime, projectType: $projectType, tools: $tools, '
        'totalPaid: $totalPaid, imagesModeRegistry: $imagesModeRegistry, '
        'numberOfMilestonesSoFar: $numberOfMilestonesSoFar, image: $image, '
        'images: $images, clientId: $clientId, startDate: $startDate, '
        'deadline: $deadline, endDate: $endDate, lastUpdated: $lastUpdated, '
        'deletionRequestedAt: $deletionRequestedAt, '
        'featureImageStoragePath: $featureImageStoragePath, '
        'ownedStoragePaths: $ownedStoragePaths}';
  }

  final String id;
  final String userId;
  final String projectName;
  final String clientName;
  final String shortDescription;
  final String? longDescription;
  final bool imageIsFile;
  final List<String> notes;
  final List<URL> urls;
  final double budget;

  /// could be for the budget, I don't quite remember, maybe to check if the
  /// budget is fixed or flexible
  final bool isFixed;

  /// if this project is a one-time project or continuous development
  final bool isOneTime;

  // Full-Stack Dev, Front-end, Backend, API,
  final String projectType;

  // Like flutter(framework), node-js(runtime), dart(language)...
  final List<String> tools;

  // We could easily get this from the milestones.reduce, but to make it
  // easier on us, let's just add it as a field.
  final double totalPaid;

  /// tracks which image in the [images] list is a file.<br />
  /// true means it's a file, false means it's not
  final List<bool> imagesModeRegistry;
  final int numberOfMilestonesSoFar;
  final String? image;
  final List<String> images;
  final String clientId;
  final DateTime startDate;
  final DateTime? deadline;
  final DateTime? endDate;
  final DateTime? lastUpdated;
  final DateTime? deletionRequestedAt;
  final String? featureImageStoragePath;
  final List<String> ownedStoragePaths;

  bool get completed => endDate != null && endDate!.isBefore(DateTime.now());

  bool get isPendingDeletion => deletionRequestedAt != null;

  Project copyWith({
    String? id,
    String? userId,
    String? projectName,
    String? clientName,
    String? shortDescription,
    String? longDescription,
    List<String>? notes,
    bool? imageIsFile,
    List<bool>? imagesModeRegistry,
    List<URL>? urls,
    double? budget,
    bool? isFixed,
    bool? isOneTime,
    String? projectType,
    List<String>? tools,
    double? totalPaid,
    int? numberOfMilestonesSoFar,
    String? image,
    List<String>? images,
    String? clientId,
    DateTime? startDate,
    DateTime? deadline,
    DateTime? endDate,
    DateTime? lastUpdated,
    DateTime? deletionRequestedAt,
    String? featureImageStoragePath,
    List<String>? ownedStoragePaths,
  }) {
    return Project(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectName: projectName ?? this.projectName,
      clientName: clientName ?? this.clientName,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      notes: notes ?? this.notes,
      imageIsFile: imageIsFile ?? this.imageIsFile,
      urls: urls ?? this.urls,
      budget: budget ?? this.budget,
      imagesModeRegistry: imagesModeRegistry ?? this.imagesModeRegistry,
      isFixed: isFixed ?? this.isFixed,
      isOneTime: isOneTime ?? this.isOneTime,
      projectType: projectType ?? this.projectType,
      tools: tools ?? this.tools,
      totalPaid: totalPaid ?? this.totalPaid,
      numberOfMilestonesSoFar:
          numberOfMilestonesSoFar ?? this.numberOfMilestonesSoFar,
      image: image ?? this.image,
      images: images ?? this.images,
      clientId: clientId ?? this.clientId,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      endDate: endDate ?? this.endDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      featureImageStoragePath:
          featureImageStoragePath ?? this.featureImageStoragePath,
      ownedStoragePaths: ownedStoragePaths ?? this.ownedStoragePaths,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    projectName,
    clientName,
    shortDescription,
    longDescription,
    imageIsFile,
    notes,
    urls,
    budget,
    isFixed,
    isOneTime,
    projectType,
    tools,
    totalPaid,
    imagesModeRegistry,
    numberOfMilestonesSoFar,
    image,
    images,
    clientId,
    startDate,
    deadline,
    endDate,
    lastUpdated,
    deletionRequestedAt,
    featureImageStoragePath,
    ownedStoragePaths,
  ];
}
