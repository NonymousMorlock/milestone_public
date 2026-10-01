import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/src/client/domain/entities/client.dart';
import 'package:milestone/src/client/presentation/providers/client_form_controller.dart';

void main() {
  late ClientFormController controller;

  setUp(() {
    controller = ClientFormController();
  });

  tearDown(() {
    controller.dispose();
  });

  test('compileCreate uses the provided reserved client id', () {
    controller.nameController.text = 'Acme';
    controller.totalSpentController.text = '2500';

    final client = controller.compileCreate(clientId: 'reserved-id');

    expect(client.id, 'reserved-id');
    expect(client.name, 'Acme');
    expect(client.totalSpent, 2500);
  });

  test('init seeds the current client values for edit mode', () {
    final client = Client(
      id: 'client-1',
      name: 'Acme',
      totalSpent: 1200,
      dateCreated: DateTime(2024),
      image: 'https://example.com/acme.png',
    );

    controller.init(client);

    expect(controller.nameController.text, 'Acme');
    expect(controller.totalSpentController.text, '1200.0');
    expect(controller.imageController.text, client.image);
  });

  test('compileUpdateData only returns changed writable fields', () {
    final client = Client(
      id: 'client-1',
      name: 'Acme',
      totalSpent: 1200,
      dateCreated: DateTime(2024),
      image: 'https://example.com/acme.png',
    );
    controller.init(client);
    controller.nameController.text = 'Acme Studio';

    final updateData = controller.compileUpdateData();

    expect(updateData, {'name': 'Acme Studio'});
    expect(controller.updateRequired, isTrue);
  });
}
