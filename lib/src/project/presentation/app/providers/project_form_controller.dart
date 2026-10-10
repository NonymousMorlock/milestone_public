import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milestone/app/di/injection_container.dart';
import 'package:milestone/core/common/providers/form_controller_with_image.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/core/helpers/cache_helper.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/data/models/u_r_l_model.dart';
import 'package:milestone/src/project/domain/entities/project.dart';
import 'package:milestone/src/project/domain/entities/u_r_l.dart';
import 'package:milestone/src/project/presentation/utils/control.dart';

typedef LinkControllers = ({
  TextEditingController titleController,
  TextEditingController urlController,
});

typedef _FeatureImageDraft = ({bool changed, bool isFile, String? value});

typedef _GalleryDraft = ({
  bool changed,
  List<String> images,
  List<bool> registry,
});

class ProjectFormController extends FormControllerWithImage
    with ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  List<Client> _clients = [];
  UnmodifiableListView<Client> get clients => UnmodifiableListView(_clients);

  List<String> _tools = [];
  UnmodifiableListView<String> get tools => UnmodifiableListView(_tools);

  Client? _selectedClient;
  Client? get selectedClient => _selectedClient;

  bool _budgetIsFixed = false;
  bool _isOneTime = false;
  bool _scalarListenersAttached = false;

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
  final List<LinkControllers> _linkControllers = [];
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

  bool get updateRequired {
    if (originalProject == null) {
      return false;
    }
    return compileUpdateData().isNotEmpty;
  }

  @override
  void changeImageMode({required bool imageIsFile}) {
    final changed = this.imageIsFile != imageIsFile;
    super.changeImageMode(imageIsFile: imageIsFile);
    if (changed) {
      notifyListeners();
    }
  }

  void init(Project project, {bool notify = true}) {
    _resetBeforeInit();
    originalProject = project;

    nameController.text = project.projectName;
    shortDescriptionController.text = project.shortDescription;
    longDescriptionController.text = project.longDescription ?? '';
    projectTypeController.text = project.projectType;
    totalPaidController.text = project.totalPaid.toString();
    budgetController.text = project.budget.toString();

    _setDateValue(
      controller: startDateController,
      notifier: startDateNotifier,
      value: project.startDate,
      requiredValue: true,
    );
    _setDateValue(
      controller: endDateController,
      notifier: endDateNotifier,
      value: project.endDate,
    );
    _setDateValue(
      controller: deadlineController,
      notifier: deadlineNotifier,
      value: project.deadline,
    );

    _selectedClient = ClientModel.empty().copyWith(
      id: project.clientId,
      name: project.clientName,
    );
    _budgetIsFixed = project.isFixed;
    _isOneTime = project.isOneTime;
    _selectedTools.addAll(_normalizeTools(project.tools));

    if (project.image != null) {
      changeImageMode(imageIsFile: project.imageIsFile);
      if (project.imageIsFile) {
        imagePathController.text = project.image!;
        imageController.text = project.image!.split('/').last;
      } else {
        imageController.text = project.image!;
      }
    }

    for (final note in project.notes) {
      _noteControllers.add(_newNoteController(note));
    }
    for (final url in project.urls) {
      _linkControllers.add(
        _newLinkControllers(
          title: url.title,
          url: url.url,
        ),
      );
    }
    for (var i = 0; i < project.images.length; i++) {
      final image = project.images[i];
      final imageIsFile =
          i < project.imagesModeRegistry.length &&
          project.imagesModeRegistry[i];
      _galleryControllers.add(
        _newGalleryControl(
          imageValue: imageIsFile ? image.split('/').last : image,
          imagePathValue: image,
          imageIsFile: imageIsFile,
        ),
      );
    }

    if (_selectedClient != null) {
      _clients = _dedupeClientsById([
        _selectedClient!,
        ..._clients,
      ]);
    }

    _attachScalarListenersOnce();
    if (notify) notifyListeners();
  }

  void _resetBeforeInit() {
    originalProject = null;

    nameController.clear();
    shortDescriptionController.clear();
    longDescriptionController.clear();
    projectTypeController.clear();
    totalPaidController.clear();
    budgetController.clear();
    startDateController.clear();
    endDateController.clear();
    deadlineController.clear();
    imageController.clear();
    imagePathController.clear();
    super.changeImageMode(imageIsFile: false);

    for (final controller in _noteControllers) {
      controller.dispose();
    }
    _noteControllers.clear();

    for (final controller in _linkControllers) {
      controller.titleController.dispose();
      controller.urlController.dispose();
    }
    _linkControllers.clear();

    for (final control in _galleryControllers) {
      control.imageController.dispose();
      control.imagePathController.dispose();
    }
    _galleryControllers.clear();

    _selectedTools.clear();
    _selectedClient = null;
    _budgetIsFixed = false;
    _isOneTime = false;
    startDateNotifier.value = null;
    endDateNotifier.value = null;
    deadlineNotifier.value = null;
  }

  void _attachScalarListenersOnce() {
    if (_scalarListenersAttached) {
      return;
    }

    for (final controller in [
      nameController,
      shortDescriptionController,
      longDescriptionController,
      projectTypeController,
      totalPaidController,
      budgetController,
      imageController,
      imagePathController,
    ]) {
      controller.addListener(notifyListeners);
    }
    for (final notifier in [
      startDateNotifier,
      endDateNotifier,
      deadlineNotifier,
    ]) {
      notifier.addListener(notifyListeners);
    }

    _scalarListenersAttached = true;
  }

  TextEditingController _newNoteController([String text = '']) {
    return TextEditingController(text: text)..addListener(notifyListeners);
  }

  LinkControllers _newLinkControllers({
    String title = '',
    String url = '',
  }) {
    final titleController = TextEditingController(text: title);
    final urlController = TextEditingController(text: url);
    titleController.addListener(notifyListeners);
    urlController.addListener(notifyListeners);
    return (
      titleController: titleController,
      urlController: urlController,
    );
  }

  Control _newGalleryControl({
    required String imageValue,
    required String imagePathValue,
    required bool imageIsFile,
  }) {
    final imageController = TextEditingController(text: imageValue);
    final imagePathController = TextEditingController(text: imagePathValue);
    imageController.addListener(notifyListeners);
    imagePathController.addListener(notifyListeners);
    return Control(
      imageController: imageController,
      imagePathController: imagePathController,
      imageIsFile: imageIsFile,
    );
  }

  void _setDateValue({
    required TextEditingController controller,
    required ValueNotifier<DateTime?> notifier,
    required DateTime? value,
    bool requiredValue = false,
  }) {
    notifier.value = value;
    if (value == null && !requiredValue) {
      controller.clear();
      return;
    }
    final date = value ?? DateTime.now();
    controller.text = DateFormat.yMMMd().format(date);
  }

  double _parseCurrency(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return 0;
    }
    return double.parse(text.onlyNumbers);
  }

  String? _normalizedNullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  List<String> _normalizeNotesList(List<String> notes) {
    return notes
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList();
  }

  List<String> _normalizedNotes() {
    return _normalizeNotesList(
      _noteControllers.map((controller) => controller.text).toList(),
    );
  }

  List<URLModel> _normalizedUrls() {
    final urls = <URLModel>[];
    for (final controller in _linkControllers) {
      final url = controller.urlController.text.trim();
      if (url.isEmpty) {
        continue;
      }
      var title = controller.titleController.text.trim();
      if (title.isEmpty) {
        title = url;
      }
      urls.add(URLModel(url: url, title: title));
    }
    return urls;
  }

  bool _deepUrlListEquals(List<URLModel> current, List<URL> original) {
    if (current.length != original.length) {
      return false;
    }
    for (var i = 0; i < current.length; i++) {
      if (current[i].url != original[i].url ||
          current[i].title != original[i].title) {
        return false;
      }
    }
    return true;
  }

  List<String> _normalizeTools(List<String> tools) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final tool in tools) {
      final trimmed = tool.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        normalized.add(trimmed);
      }
    }
    normalized.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return normalized;
  }

  List<Client> _dedupeClientsById(List<Client> clients) {
    final deduped = <Client>[];
    final seen = <String>{};
    for (final client in clients) {
      if (seen.add(client.id)) {
        deduped.add(client);
      }
    }
    return deduped;
  }

  List<bool> _normalizedOriginalGalleryRegistry() {
    final original = originalProject;
    if (original == null) {
      return const <bool>[];
    }
    if (original.imagesModeRegistry.length == original.images.length) {
      return List<bool>.from(original.imagesModeRegistry);
    }
    return List<bool>.filled(original.images.length, false);
  }

  _FeatureImageDraft _featureImageDraft() {
    final original = originalProject;
    if (original == null) {
      return (changed: false, isFile: false, value: null);
    }

    final visibleValue = imageController.text.trim();
    if (visibleValue.isEmpty) {
      return (
        changed: original.image != null,
        isFile: false,
        value: null,
      );
    }

    if (imageIsFile) {
      final localPath = imagePathController.text.trim();
      return (
        changed: !original.imageIsFile || localPath.isNotEmpty,
        isFile: true,
        value: localPath,
      );
    }

    return (
      changed: visibleValue != original.image,
      isFile: false,
      value: visibleValue,
    );
  }

  _GalleryDraft _galleryDraft() {
    final images = <String>[];
    final registry = <bool>[];

    for (final control in _galleryControllers) {
      final value = control.imageIsFile
          ? control.imagePathController.text.trim()
          : control.imageController.text.trim();
      if (value.isEmpty) {
        continue;
      }
      images.add(value);
      registry.add(control.imageIsFile);
    }

    final original = originalProject;
    final changed =
        original == null ||
        !const ListEquality<String>().equals(images, original.images) ||
        !const ListEquality<bool>().equals(
          registry,
          _normalizedOriginalGalleryRegistry(),
        );

    return (
      changed: changed,
      images: images,
      registry: registry,
    );
  }

  DataMap compileUpdateData() {
    assert(originalProject != null, 'originalProject may not be null');
    final original = originalProject;
    if (original == null) {
      return <String, dynamic>{};
    }

    final update = <String, dynamic>{};

    final currentName = nameController.text.trim();
    if (currentName != original.projectName) {
      update['projectName'] = currentName;
    }

    final currentClient = _selectedClient;
    if (currentClient != null && currentClient.id != original.clientId) {
      update['clientId'] = currentClient.id;
      update['clientName'] = currentClient.name;
    }

    final currentShort = shortDescriptionController.text.trim();
    if (currentShort != original.shortDescription) {
      update['shortDescription'] = currentShort;
    }

    final currentLong = _normalizedNullableText(longDescriptionController);
    if (currentLong != original.longDescription) {
      update['longDescription'] = currentLong;
    }

    final currentBudget = _parseCurrency(budgetController);
    if (currentBudget != original.budget) {
      update['budget'] = currentBudget;
    }

    if (_budgetIsFixed != original.isFixed) {
      update['isFixed'] = _budgetIsFixed;
    }

    if (_isOneTime != original.isOneTime) {
      update['isOneTime'] = _isOneTime;
    }

    final currentProjectType = projectTypeController.text.trim();
    if (currentProjectType != original.projectType) {
      update['projectType'] = currentProjectType;
    }

    final currentStartDate = startDateNotifier.value;
    if (currentStartDate == null) {
      throw StateError('startDate may not be null in edit mode');
    }
    if (currentStartDate != original.startDate) {
      update['startDate'] = currentStartDate;
    }

    if (deadlineNotifier.value != original.deadline) {
      update['deadline'] = deadlineNotifier.value;
    }

    if (endDateNotifier.value != original.endDate) {
      update['endDate'] = endDateNotifier.value;
    }

    final currentNotes = _normalizedNotes();
    final originalNotes = _normalizeNotesList(original.notes);
    if (!const ListEquality<String>().equals(currentNotes, originalNotes)) {
      update['notes'] = currentNotes;
    }

    final currentUrls = _normalizedUrls();
    if (!_deepUrlListEquals(currentUrls, original.urls)) {
      update['urls'] = currentUrls;
    }

    final currentTools = _normalizeTools(_selectedTools);
    final originalTools = _normalizeTools(original.tools);
    if (!const ListEquality<String>().equals(currentTools, originalTools)) {
      update['tools'] = currentTools;
    }

    final featureImageDraft = _featureImageDraft();
    if (featureImageDraft.changed) {
      update['image'] = featureImageDraft.value;
      if (featureImageDraft.isFile) {
        update['imageIsFile'] = true;
      }
    }

    final galleryDraft = _galleryDraft();
    if (galleryDraft.changed) {
      update['images'] = galleryDraft.images;
      update['imagesModeRegistry'] = galleryDraft.registry;
    }

    return update;
  }

  void changeBudgetFlexibility({required bool isFixed}) {
    if (_budgetIsFixed != isFixed) {
      _budgetIsFixed = isFixed;
      notifyListeners();
    }
  }

  void changeContinuity({required bool isOneTime}) {
    if (_isOneTime != isOneTime) {
      _isOneTime = isOneTime;
      notifyListeners();
    }
  }

  void setClients(List<Client> clients) {
    final selectedBeforeRefresh = _selectedClient;
    final preserveBaselineCurrentClient =
        selectedBeforeRefresh != null &&
        originalProject != null &&
        selectedBeforeRefresh.id == originalProject!.clientId;

    final mergedClients = _dedupeClientsById([
      if (preserveBaselineCurrentClient) selectedBeforeRefresh,
      ...clients,
      if (selectedBeforeRefresh != null &&
          clients.every((client) => client.id != selectedBeforeRefresh.id))
        selectedBeforeRefresh,
    ]);

    _clients = mergedClients;

    if (selectedBeforeRefresh != null) {
      if (preserveBaselineCurrentClient) {
        _selectedClient = selectedBeforeRefresh;
      } else {
        final match = mergedClients.firstWhereOrNull(
          (client) => client.id == selectedBeforeRefresh.id,
        );
        if (match != null) {
          _selectedClient = match;
        }
      }
    }

    notifyListeners();
  }

  void selectClient(Client? client) {
    if (_selectedClient == client) {
      return;
    }

    _selectedClient = client;
    if (client != null) {
      _clients = _dedupeClientsById([client, ..._clients]);
    }
    notifyListeners();
  }

  void addNote() {
    _noteControllers.add(_newNoteController());
    notifyListeners();
  }

  void removeNote(int index) {
    _noteControllers[index].dispose();
    _noteControllers.removeAt(index);
    notifyListeners();
  }

  void addLink() {
    _linkControllers.add(_newLinkControllers());
    notifyListeners();
  }

  void removeLink(int index) {
    _linkControllers[index].titleController.dispose();
    _linkControllers[index].urlController.dispose();
    _linkControllers.removeAt(index);
    notifyListeners();
  }

  void addToGallery() {
    _galleryControllers.add(
      _newGalleryControl(
        imageValue: '',
        imagePathValue: '',
        imageIsFile: false,
      ),
    );
    notifyListeners();
  }

  void removeImageFromGallery(int index) {
    _galleryControllers[index].imageController.dispose();
    _galleryControllers[index].imagePathController.dispose();
    _galleryControllers.removeAt(index);
    notifyListeners();
  }

  void changeGalleryImageMode({required bool imageIsFile, required int index}) {
    if (_galleryControllers[index].imageIsFile != imageIsFile) {
      _galleryControllers[index] = _galleryControllers[index].copyWith(
        imageIsFile: imageIsFile,
      );
      notifyListeners();
    }
  }

  void setTools(List<String> tools) {
    final normalizedTools = _normalizeTools(tools);
    if (!const ListEquality<String>().equals(_tools, normalizedTools)) {
      _tools = normalizedTools;
      notifyListeners();
    }
  }

  bool _addToolLocally(String tool) {
    if (tool.trim().isEmpty) return false;

    if (_tools
        .where((element) => element.toLowerCase() == tool.toLowerCase())
        .isEmpty) {
      _tools.add(tool);
      return true;
    }

    return false;
  }

  Future<void> addTool(String tool) async {
    _addToolLocally(tool);
    selectTool(tool);
    await CacheHelper.instance.cacheTools(_tools);
  }

  Future<void> addTools(List<String> tools) async {
    var added = false;
    for (final tool in tools) {
      added = _addToolLocally(tool) || added;
    }
    if (added) {
      await CacheHelper.instance.cacheTools(_tools);
      notifyListeners();
    }
  }

  Future<void> removeTool(String tool) async {
    final matchingElements = _tools.where(
      (element) => element.toLowerCase() == tool.toLowerCase(),
    );
    if (matchingElements.isNotEmpty) {
      _tools.remove(matchingElements.first);
      deselectTool(tool);
      await CacheHelper.instance.cacheTools(_tools);
    }
  }

  void selectTool(String tool) {
    if (_selectedTools
        .where((element) => element.toLowerCase() == tool.toLowerCase())
        .isEmpty) {
      _selectedTools.add(tool);
      notifyListeners();
    }
  }

  void deselectTool(String tool) {
    final matchingElements = _selectedTools.where(
      (element) => element.toLowerCase() == tool.toLowerCase(),
    );
    if (matchingElements.isNotEmpty) {
      _selectedTools.remove(matchingElements.first);
      notifyListeners();
    }
  }

  ProjectModel compile() {
    String? image = imageIsFile
        ? imagePathController.text.trim()
        : imageController.text.trim();
    if (image.isEmpty) {
      image = null;
    }
    final userId = sl<FirebaseAuth>().currentUser!.uid;
    final projectName = nameController.text.trim();
    final clientName = _selectedClient!.name;
    final shortDescription = shortDescriptionController.text.trim();
    String? longDescription = longDescriptionController.text.trim();
    if (longDescription.isEmpty) {
      longDescription = null;
    }
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
    final notes = _noteControllers
        .map((controller) => controller.text.trim())
        .toList();

    final urls = _linkControllers.map((controller) {
      var title = controller.titleController.text.trim();
      if (title.isEmpty) {
        title = controller.urlController.text.trim();
      }
      return URLModel(
        url: controller.urlController.text.trim(),
        title: title,
      );
    }).toList();

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
    budgetController.dispose();
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
