import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_menu/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns null when no menu id has been saved', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});

    expect(await StorageService().getMenuId(), isNull);
  });

  test('reads a previously saved menu id', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final storageService = StorageService();

    await storageService.saveMenuId('menu-1');

    expect(await storageService.getMenuId(), 'menu-1');
  });

  test('reads the menu id written by another instance', () async {
    FlutterSecureStorage.setMockInitialValues(
        <String, String>{'menu-id': 'menu-1'});

    expect(await StorageService().getMenuId(), 'menu-1');
  });

  test('overwrites the stored menu id', () async {
    FlutterSecureStorage.setMockInitialValues(
        <String, String>{'menu-id': 'menu-1'});
    final storageService = StorageService();

    await storageService.saveMenuId('menu-2');

    expect(await storageService.getMenuId(), 'menu-2');
  });
}
