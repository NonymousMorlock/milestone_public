import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milestone/core/extensions/string_extensions.dart';
import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/domain/entities/milestone.dart';

class MilestoneFormController with ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final shortDescriptionController = TextEditingController();
  final amountPaidController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final startDateNotifier = ValueNotifier<DateTime?>(null);
  final endDateNotifier = ValueNotifier<DateTime?>(null);

  final List<TextEditingController> _noteControllers = [];
  bool _scalarListenersAttached = false;

  Milestone? originalMilestone;

  UnmodifiableListView<TextEditingController> get noteControllers =>
      UnmodifiableListView(_noteControllers);

  bool get updateRequired {
    if (originalMilestone == null) {
      return false;
    }
    try {
      return compileUpdateData().isNotEmpty;
    } on Exception {
      return true;
    }
  }

  void init(Milestone milestone, {bool notify = true}) {
    _resetBeforeInit();
    originalMilestone = milestone;
    titleController.text = milestone.title;
    shortDescriptionController.text = milestone.shortDescription ?? '';
    amountPaidController.text = milestone.amountPaid?.toString() ?? '';
    _setDateValue(
      controller: startDateController,
      notifier: startDateNotifier,
      value: milestone.startDate,
    );
    _setDateValue(
      controller: endDateController,
      notifier: endDateNotifier,
      value: milestone.endDate,
    );
    for (final note in milestone.notes) {
      _noteControllers.add(_newNoteController(note));
    }
    _attachScalarListenersOnce();
    if (notify) {
      notifyListeners();
    }
  }

  void _resetBeforeInit() {
    originalMilestone = null;
    titleController.clear();
    shortDescriptionController.clear();
    amountPaidController.clear();
    startDateController.clear();
    endDateController.clear();
    startDateNotifier.value = null;
    endDateNotifier.value = null;

    for (final controller in _noteControllers) {
      controller.dispose();
    }
    _noteControllers.clear();
  }

  void _attachScalarListenersOnce() {
    if (_scalarListenersAttached) {
      return;
    }

    for (final controller in [
      titleController,
      shortDescriptionController,
      amountPaidController,
      startDateController,
      endDateController,
    ]) {
      controller.addListener(notifyListeners);
    }

    for (final notifier in [startDateNotifier, endDateNotifier]) {
      notifier.addListener(notifyListeners);
    }

    _scalarListenersAttached = true;
  }

  TextEditingController _newNoteController([String text = '']) {
    return TextEditingController(text: text)..addListener(notifyListeners);
  }

  void _setDateValue({
    required TextEditingController controller,
    required ValueNotifier<DateTime?> notifier,
    required DateTime? value,
  }) {
    notifier.value = value;
    if (value == null) {
      controller.clear();
      return;
    }
    controller.text = DateFormat.yMMMd().format(value);
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

  String? normalizeOptionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  List<String> normalizeNotes() {
    return _noteControllers
        .map((controller) => controller.text.trim())
        .where((note) => note.isNotEmpty)
        .toList();
  }

  double? parseAmountPaid() {
    final value = amountPaidController.text.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(value.onlyNumbers);
    if (parsed == null || parsed <= 0) {
      throw const FormatException('Amount paid must be greater than zero.');
    }
    return parsed;
  }

  String? amountPaidValidationMessage(String? _) {
    final value = amountPaidController.text.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(value.onlyNumbers);
    if (parsed == null) {
      return 'Enter a valid payment amount';
    }
    if (parsed <= 0) {
      return 'Amount paid must be greater than zero';
    }
    return null;
  }

  String? chronologyValidationMessage() {
    final startDate = startDateNotifier.value;
    final endDate = endDateNotifier.value;
    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      return 'End date cannot be earlier than start date';
    }
    return null;
  }

  void validateChronology() {
    final error = chronologyValidationMessage();
    if (error != null) {
      throw StateError(error);
    }
  }

  MilestoneModel compileForCreate({required String projectId}) {
    validateChronology();
    return MilestoneModel(
      id: '',
      projectId: projectId,
      title: titleController.text.trim(),
      shortDescription: normalizeOptionalText(shortDescriptionController),
      notes: normalizeNotes(),
      amountPaid: parseAmountPaid(),
      startDate: startDateNotifier.value,
      endDate: endDateNotifier.value,
      dateCreated: DateTime.now(),
    );
  }

  DataMap compileUpdateData() {
    assert(originalMilestone != null, 'originalMilestone may not be null');
    final original = originalMilestone;
    if (original == null) {
      return <String, dynamic>{};
    }

    validateChronology();

    final update = <String, dynamic>{};

    final currentTitle = titleController.text.trim();
    if (currentTitle != original.title) {
      update['title'] = currentTitle;
    }

    final currentShortDescription = normalizeOptionalText(
      shortDescriptionController,
    );
    if (currentShortDescription != original.shortDescription) {
      update['shortDescription'] = currentShortDescription;
    }

    final currentNotes = normalizeNotes();
    final originalNotes = original.notes
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList();
    if (!const ListEquality<String>().equals(currentNotes, originalNotes)) {
      update['notes'] = currentNotes;
    }

    final currentAmountPaid = parseAmountPaid();
    if (currentAmountPaid != original.amountPaid) {
      update['amountPaid'] = currentAmountPaid;
    }

    if (startDateNotifier.value != original.startDate) {
      update['startDate'] = startDateNotifier.value;
    }

    if (endDateNotifier.value != original.endDate) {
      update['endDate'] = endDateNotifier.value;
    }

    return update;
  }

  @override
  void dispose() {
    titleController.dispose();
    shortDescriptionController.dispose();
    amountPaidController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    startDateNotifier.dispose();
    endDateNotifier.dispose();
    for (final controller in _noteControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
