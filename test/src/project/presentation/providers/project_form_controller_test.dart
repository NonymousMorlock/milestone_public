import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/data/models/client_model.dart';
import 'package:milestone/src/project/data/models/project_model.dart';
import 'package:milestone/src/project/data/models/u_r_l_model.dart';
import 'package:milestone/src/project/presentation/app/providers/project_form_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectFormController controller;

  ProjectModel buildProject({
    List<String>? notes,
    List<String>? tools,
    String clientId = 'client-1',
    String clientName = 'Client One',
  }) {
    return ProjectModel.empty().copyWith(
      id: 'project-1',
      projectName: 'Project One',
      shortDescription: 'Short description',
      longDescription: 'Long description',
      clientId: clientId,
      clientName: clientName,
      notes: notes ?? const ['Note One'],
      tools: tools ?? const ['Flutter'],
      urls: const [
        URLModel(
          url: 'https://example.com',
          title: 'Example',
        ),
      ],
      images: const [],
      imagesModeRegistry: const [],
      totalPaid: 100,
      numberOfMilestonesSoFar: 4,
    );
  }

  setUp(() {
    controller = ProjectFormController();
  });

  tearDown(() {
    controller.dispose();
  });

  test(
    'compileUpdateData returns empty for unchanged project with legacy blank'
    ' notes',
    () {
      controller.init(
        buildProject(
          notes: const ['Note One', ''],
        ),
      );

      expect(controller.compileUpdateData(), isEmpty);
      expect(controller.updateRequired, isFalse);
    },
  );

  test('editing a seeded note triggers notification and dirty state', () {
    controller.init(buildProject());
    var notifications = 0;
    controller.addListener(() {
      notifications++;
    });

    controller.noteControllers.first.text = 'Updated note';

    expect(notifications, greaterThan(0));
    expect(controller.updateRequired, isTrue);
    expect(
      controller.compileUpdateData()['notes'],
      equals(const ['Updated note']),
    );
  });

  test('repeated init does not stack duplicate scalar listeners', () {
    controller
      ..init(buildProject())
      ..init(
        buildProject(
          clientName: 'Client Two',
          tools: const ['Dart'],
        ),
      );
    var notifications = 0;
    controller.addListener(() {
      notifications++;
    });

    controller.nameController.text = 'Renamed project';

    expect(notifications, equals(1));
  });

  test(
    'setClients preserves a newly selected client when late list omits it',
    () {
      controller.init(buildProject());
      final replacementClient = ClientModel.empty().copyWith(
        id: 'client-2',
        name: 'Client Two',
      );

      controller
        ..selectClient(replacementClient)
        ..setClients([
          ClientModel.empty().copyWith(
            id: 'client-1',
            name: 'Client One',
          ),
        ]);

      expect(controller.selectedClient?.id, equals('client-2'));
      expect(
        controller.clients.any((client) => client.id == 'client-2'),
        isTrue,
      );
    },
  );

  test(
    'setClients preserves the project-baseline label for the unchanged'
    ' current client',
    () {
      controller
        ..init(
          buildProject(
            clientName: 'Project Baseline Client',
          ),
        )
        ..setClients([
          ClientModel.empty().copyWith(
            id: 'client-1',
            name: 'Stale Client Doc Label',
          ),
        ]);

      expect(
        controller.selectedClient?.name,
        equals('Project Baseline Client'),
      );
    },
  );

  test(
    'compileUpdateData excludes rollup-owned values even if controllers'
    ' change',
    () {
      controller.init(buildProject());
      controller.totalPaidController.text = '999';

      final updateData = controller.compileUpdateData();

      expect(updateData.containsKey('totalPaid'), isFalse);
      expect(updateData.containsKey('numberOfMilestonesSoFar'), isFalse);
    },
  );
}
