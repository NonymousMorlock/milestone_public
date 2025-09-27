import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:milestone/core/common/providers/form_controller_with_image.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/core/helpers/cache_helper.dart';
import 'package:milestone/core/services/injection_container.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/data/models/u_r_l_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/entities/u_r_l.dart';
import 'package:milestone/src/project/presentation/utils/control.dart';

typedef LinkControllers = ({
  TextEditingController titleController,
  TextEditingController urlController
});

class ProjectFormController extends FormControllerWithImage
    with ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  List<Client> _clients = [
    // ClientModel.empty().copyWith(id: '1', name: 'Oligarch Johnson'),
    // ClientModel.empty().copyWith(id: '2', name: 'June Prince'),
    // ClientModel.empty().copyWith(id: '3', name: 'Moon Son'),
    // ClientModel.empty().copyWith(id: '4', name: 'Jagger Pisces'),
    // ClientModel.empty().copyWith(id: '5', name: 'Ink Butter'),
    // ClientModel.empty().copyWith(id: '6', name: 'Dark Ring'),
    // ClientModel.empty().copyWith(id: '7', name: 'Leech Bird'),
  ];

  UnmodifiableListView<Client> get clients => UnmodifiableListView(_clients);

  List<String> _tools = [];

  UnmodifiableListView<String> get tools => UnmodifiableListView(_tools);

  Client? _selectedClient;

  Client? get selectedClient => _selectedClient;

  bool _budgetIsFixed = false;

  bool _isOneTime = false;

  bool get budgetIsFixed => _budgetIsFixed;

  bool get isOneTime => _isOneTime;

  final budgetController = TextEditingController();
  final nameController = TextEditingController();
  final shortDescriptionController = TextEditingController();
  final longDescriptionController = TextEditingController();
  final projectTypeController = TextEditingController();
  final totalPaidController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final deadlineController = TextEditingController();
  final startDateNotifier = ValueNotifier<DateTime?>(null);
  final endDateNotifier = ValueNotifier<DateTime?>(null);
  final deadlineNotifier = ValueNotifier<DateTime?>(null);

  Project? originalProject;

  final List<TextEditingController> _noteControllers = [];
  final List<
      ({
        TextEditingController titleController,
        TextEditingController urlController
      })> _linkControllers = [];
  final List<Control> _galleryControllers = [];
  final List<String> _selectedTools = [];

  UnmodifiableListView<TextEditingController> get noteControllers =>
      UnmodifiableListView(_noteControllers);

  UnmodifiableListView<LinkControllers> get linkControllers =>
      UnmodifiableListView(_linkControllers);

  UnmodifiableListView<Control> get galleryControllers =>
      UnmodifiableListView(_galleryControllers);

  UnmodifiableListView<String> get selectedTools =>
      UnmodifiableListView(_selectedTools);

  bool _updateRequired = false;

  bool get updateRequired => _updateRequired;

  void addListenersToControllersForUpdate() {
    nameController.addListener(() {
      _updateRequired = originalProject!.projectName != nameController.text;
      notifyListeners();
    });
    shortDescriptionController.addListener(() {
      _updateRequired =
          originalProject!.shortDescription != shortDescriptionController.text;
      notifyListeners();
    });
    longDescriptionController.addListener(() {
      _updateRequired =
          originalProject!.longDescription != longDescriptionController.text;
      notifyListeners();
    });
    projectTypeController.addListener(() {
      _updateRequired =
          originalProject!.projectType != projectTypeController.text;
      notifyListeners();
    });
    totalPaidController.addListener(() {
      _updateRequired = originalProject!.totalPaid !=
          double.parse(totalPaidController.text.onlyNumbers);
      notifyListeners();
    });
    budgetController.addListener(() {
      _updateRequired = originalProject!.budget !=
          double.parse(budgetController.text.onlyNumbers);
      notifyListeners();
    });
    startDateNotifier.addListener(() {
      _updateRequired = originalProject!.startDate != startDateNotifier.value;
      notifyListeners();
    });
    endDateNotifier.addListener(() {
      _updateRequired = originalProject!.endDate != endDateNotifier.value;
      notifyListeners();
    });
    deadlineNotifier.addListener(() {
      _updateRequired = originalProject!.deadline != deadlineNotifier.value;
      notifyListeners();
    });

    for (final controller in _noteControllers) {
      controller.addListener(checkNoteUpdate);
    }

    for (final controller in _linkControllers) {
      controller.titleController.addListener(checkLinkUpdate);
      controller.urlController.addListener(checkLinkUpdate);
    }

    for (final control in _galleryControllers) {
      control.imageController.addListener(checkGalleryUpdate);
      control.imagePathController.addListener(checkGalleryUpdate);
    }
  }

  void checkGalleryUpdate() {
    _updateRequired = !const ListEquality<String>().equals(
      originalProject?.images,
      _galleryControllers
          .map((control) => control.imageController.text.trim())
          .toList(),
    );
    notifyListeners();
  }

  void checkLinkUpdate() {
    _updateRequired = !const ListEquality<URL>().equals(
      originalProject?.urls,
      _linkControllers
          .map(
            (controller) => URLModel(
              title: controller.titleController.text.trim(),
              url: controller.urlController.text.trim(),
            ),
          )
          .toList(),
    );
    notifyListeners();
  }

  void init(Project project) {
    originalProject = project;
    nameController.text = project.projectName;
    shortDescriptionController.text = project.shortDescription;
    longDescriptionController.text = project.longDescription ?? '';
    projectTypeController.text = project.projectType;
    totalPaidController.text = project.totalPaid.toString();
    budgetController.text = project.budget.toString();
    startDateNotifier.value = project.startDate;
    endDateNotifier.value = project.endDate;
    deadlineNotifier.value = project.deadline;
    _selectedClient = ClientModel.empty().copyWith(
      id: project.clientId,
      name: project.clientName,
    );
    _budgetIsFixed = project.isFixed;
    _isOneTime = project.isOneTime;
    _selectedTools.addAll(project.tools);
    if (project.image != null) {
      changeImageMode(imageIsFile: project.imageIsFile);
      if (project.imageIsFile) {
        imagePathController.text = project.image!;
      } else {
        imageController.text = project.image!;
      }
    }
    for (final note in project.notes) {
      _noteControllers.add(TextEditingController(text: note));
    }
    for (final url in project.urls) {
      _linkControllers.add(
        (
          titleController: TextEditingController(text: url.title),
          urlController: TextEditingController(text: url.url),
        ),
      );
    }
    for (var i = 0; i < project.images.length; i++) {
      _galleryControllers.add(
        Control(
          imageController: TextEditingController(text: project.images[i]),
          imagePathController: TextEditingController(text: project.images[i]),
          imageIsFile: project.imagesModeRegistry[i],
        ),
      );
    }
    notifyListeners();
    addListenersToControllersForUpdate();
  }

  void changeBudgetFlexibility({required bool isFixed}) {
    if (_budgetIsFixed != isFixed) {
      _budgetIsFixed = isFixed;
      _updateRequired = originalProject!.isFixed != isFixed;
      notifyListeners();
    }
  }

  void changeContinuity({required bool isOneTime}) {
    if (_isOneTime != isOneTime) {
      _isOneTime = isOneTime;
      _updateRequired = originalProject!.isOneTime != isOneTime;
      notifyListeners();
    }
  }

  void setClients(List<Client> clients) {
    _clients = clients;
    notifyListeners();
  }

  void selectClient(Client? client) {
    if (_selectedClient != client) {
      _selectedClient = client;
      _updateRequired = originalProject!.clientId != client!.id;
      notifyListeners();
    }
    if (client != null && !_clients.contains(client)) {
      _clients.add(client);
      notifyListeners();
    }
  }

  void checkNoteUpdate() {
    _updateRequired = !const ListEquality<String>().equals(
      originalProject?.notes,
      _noteControllers.map((controller) => controller.text.trim()).toList(),
    );
    notifyListeners();
  }

  void addNote() {
    _noteControllers.add(TextEditingController()..addListener(checkNoteUpdate));
    checkNoteUpdate();
  }

  void removeNote(int index) {
    _noteControllers[index].dispose();
    _noteControllers.removeAt(index);
    checkNoteUpdate();
  }

  void addLink() {
    _linkControllers.add(
      (
        titleController: TextEditingController()..addListener(checkLinkUpdate),
        urlController: TextEditingController()..addListener(checkLinkUpdate),
      ),
    );
    checkLinkUpdate();
  }

  void removeLink(int index) {
    // _linkControllers[index].dispose();
    _linkControllers[index].titleController.dispose();
    _linkControllers[index].urlController.dispose();
    _linkControllers.removeAt(index);
    checkLinkUpdate();
  }

  void addToGallery() {
    _galleryControllers.add(
      Control(
        imageController: TextEditingController()
          ..addListener(checkGalleryUpdate),
        imagePathController: TextEditingController()
          ..addListener(checkGalleryUpdate),
      ),
    );
    checkGalleryUpdate();
  }

  void removeImageFromGallery(int index) {
    _galleryControllers[index].imageController.dispose();
    _galleryControllers[index].imagePathController.dispose();
    _galleryControllers.removeAt(index);
    checkGalleryUpdate();
  }

  void changeGalleryImageMode({required bool imageIsFile, required int index}) {
    if (_galleryControllers[index].imageIsFile != imageIsFile) {
      _galleryControllers[index] = _galleryControllers[index].copyWith(
        imageIsFile: imageIsFile,
      );
      checkGalleryUpdate();
    }
  }

  void setTools(List<String> tools) {
    _tools.sort((a, b) => a.compareTo(b));
    tools.sort((a, b) => a.compareTo(b));
    if (!const ListEquality<String>().equals(_tools, tools)) {
      _tools = tools;
    }
    _updateRequired = !const ListEquality<String>().equals(
      originalProject?.tools,
      _selectedTools,
    );
    notifyListeners();
  }

  /// For adding a new [tool]. <br /><br />
  /// Only use this when the tool doesn't already exist and user is adding
  /// new tool. If the tool already exists, you want to use the [selectTool]
  /// instead.
  void addTool(String tool) {
    if (tool.trim().isEmpty) return;
    if (_tools
        .where((element) => element.toLowerCase() == tool.toLowerCase())
        .isEmpty) {
      _tools.add(tool);
      selectTool(tool);
      CacheHelper.instance.cacheTools(_tools);
    }
  }

  /// For deleting an existing [tool]. <br /><br />
  /// Only use this when user is trying to delete a tool from the tools list
  /// rendered for them to pick from. <br />
  /// If you need to delete a tool from the user's already selected tools, use
  /// [deselectTool] rather
  void removeTool(String tool) {
    final matchingElements = _tools.where(
      (element) => element.toLowerCase() == tool.toLowerCase(),
    );
    if (matchingElements.isNotEmpty) {
      _tools.remove(matchingElements.first);
      deselectTool(tool);
      CacheHelper.instance.cacheTools(_tools);
    }
  }

  /// For selecting an already existing tool
  void selectTool(String tool) {
    if (_selectedTools
        .where((element) => element.toLowerCase() == tool.toLowerCase())
        .isEmpty) {
      _selectedTools.add(tool);
      _updateRequired = !const ListEquality<String>().equals(
        originalProject?.tools,
        _selectedTools,
      );
      notifyListeners();
    }
  }

  /// For removing an already existing tool
  void deselectTool(String tool) {
    final matchingElements = _selectedTools.where(
      (element) => element.toLowerCase() == tool.toLowerCase(),
    );
    if (matchingElements.isNotEmpty) {
      _selectedTools.remove(matchingElements.first);
      notifyListeners();

      _updateRequired = !const ListEquality<String>().equals(
        originalProject?.tools,
        _selectedTools,
      );
    }
  }

  ProjectModel compile() {
    String? image = imageIsFile
        ? imagePathController.text.trim()
        : imageController.text.trim();
    if (image.isEmpty) image = null;
    final userId = sl<FirebaseAuth>().currentUser!.uid;
    final projectName = nameController.text.trim();
    final clientName = _selectedClient!.name;
    final shortDescription = shortDescriptionController.text.trim();
    String? longDescription = longDescriptionController.text.trim();
    if (longDescription.isEmpty) longDescription = null;
    final budget = budgetController.text.trim().isEmpty
        ? 0.0
        : double.parse(
            budgetController.text.trim().onlyNumbers,
          );
    final projectType = projectTypeController.text.trim();
    final totalPaid = totalPaidController.text.trim().isEmpty
        ? 0.0
        : double.parse(
            totalPaidController.text.trim().onlyNumbers,
          );
    final clientId = _selectedClient!.id;
    final startDate = startDateNotifier.value;
    final deadline = deadlineNotifier.value;
    final endDate = endDateNotifier.value;
    final images = <String>[];
    final imagesModeRegistry = <bool>[];

    for (final control in _galleryControllers) {
      if (control.imageIsFile) {
        images.add(control.imagePathController.text.trim());
      } else {
        images.add(control.imageController.text.trim());
      }
      imagesModeRegistry.add(control.imageIsFile);
    }
    final notes =
        _noteControllers.map((controller) => controller.text.trim()).toList();

    final urls = _linkControllers.map(
      (controller) {
        var title = controller.titleController.text.trim();
        if (title.isEmpty) title = controller.urlController.text.trim();
        return URLModel(
          url: controller.urlController.text.trim(),
          title: title,
        );
      },
    ).toList();
    return ProjectModel(
      id: '',
      userId: userId,
      projectName: projectName,
      clientName: clientName,
      shortDescription: shortDescription,
      longDescription: longDescription,
      budget: budget,
      projectType: projectType,
      totalPaid: totalPaid,
      numberOfMilestonesSoFar: 0,
      clientId: clientId,
      deadline: deadline,
      endDate: endDate,
      startDate: startDate ?? DateTime.now(),
      imageIsFile: imageIsFile,
      notes: notes,
      urls: urls,
      isFixed: _budgetIsFixed,
      isOneTime: _isOneTime,
      tools: _selectedTools,
      image: image,
      images: images,
      imagesModeRegistry: imagesModeRegistry,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    imageController.dispose();
    imagePathController.dispose();
    shortDescriptionController.dispose();
    longDescriptionController.dispose();
    projectTypeController.dispose();
    totalPaidController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    deadlineController.dispose();
    startDateNotifier.dispose();
    endDateNotifier.dispose();
    deadlineNotifier.dispose();
    for (final controller in _noteControllers) {
      controller.dispose();
    }
    for (final controller in _linkControllers) {
      controller.titleController.dispose();
      controller.urlController.dispose();
    }
    for (final control in _galleryControllers) {
      control.imageController.dispose();
      control.imagePathController.dispose();
    }
    super.dispose();
  }
}
