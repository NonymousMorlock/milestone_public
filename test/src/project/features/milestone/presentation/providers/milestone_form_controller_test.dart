import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/project/features/milestone/data/models/milestone_model.dart';
import 'package:milestone/src/project/features/milestone/presentation/providers/milestone_form_controller.dart';

void main() {
  late MilestoneFormController controller;

  final tMilestone = MilestoneModel.empty().copyWith(
    id: 'milestone-1',
    projectId: 'project-1',
    title: 'Discovery',
    shortDescription: 'Agree scope',
    notes: const ['Draft scope'],
    amountPaid: 120,
    startDate: DateTime(2025, 1, 10),
    endDate: DateTime(2025, 1, 20),
  );

  setUp(() {
    controller = MilestoneFormController();
  });

  tearDown(() {
    controller.dispose();
  });

  test('compileUpdateData returns an empty map when nothing changed', () {
    controller.init(tMilestone);

    expect(controller.updateRequired, isFalse);
    expect(controller.compileUpdateData(), isEmpty);
  });

  test('compileUpdateData supports clearing notes and amountPaid', () {
    controller
      ..init(tMilestone)
      ..removeNote(0)
      ..amountPaidController.clear();

    final result = controller.compileUpdateData();

    expect(
      result,
      containsPair('notes', <String>[]),
    );
    expect(result, containsPair('amountPaid', isNull));
  });

  test(
    'compileForCreate throws when the end date is earlier than the start',
    () {
      controller.titleController.text = 'Launch';
      controller.startDateNotifier.value = DateTime(2025, 2, 10);
      controller.endDateNotifier.value = DateTime(2025, 2, 9);

      expect(
        () => controller.compileForCreate(projectId: 'project-1'),
        throwsStateError,
      );
    },
  );
}
