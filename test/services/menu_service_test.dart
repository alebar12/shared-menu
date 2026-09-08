import 'package:flutter_test/flutter_test.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/services/menu_service.dart';

import '../fakes.dart';

void main() {
  late FakeApiClient apiClient;
  late FakeStorageService storageService;
  late MenuService menuService;

  setUp(() {
    apiClient = FakeApiClient();
    storageService = FakeStorageService();
    menuService = MenuService(apiClient: apiClient, storageService: storageService);
  });

  group('currentMenuId', () {
    test('returns the stored menu id without calling the api', () async {
      storageService.storedMenuId = 'stored-menu';

      expect(await menuService.currentMenuId(), 'stored-menu');
      expect(apiClient.fetchMenuIdCalls, 0);
      expect(storageService.savedMenuIds, isEmpty);
    });

    test('creates and stores a menu id when none is stored', () async {
      apiClient.menuIdToReturn = 'new-menu';

      expect(await menuService.currentMenuId(), 'new-menu');
      expect(apiClient.fetchMenuIdCalls, 1);
      expect(storageService.savedMenuIds, <String>['new-menu']);
    });

    test('caches the resolved menu id across calls', () async {
      await menuService.currentMenuId();
      await menuService.currentMenuId();

      expect(apiClient.fetchMenuIdCalls, 1);
    });

    test('propagates the api failure', () async {
      apiClient.fetchMenuIdError = ApiException(500, 'boom');

      await expectLater(
        menuService.currentMenuId(),
        throwsA(isA<ApiException>()),
      );
    });

    test('clears the cache after a failure so the next call retries', () async {
      apiClient.fetchMenuIdError = ApiException(500, 'boom');
      await expectLater(menuService.currentMenuId(), throwsA(isA<ApiException>()));

      apiClient.fetchMenuIdError = null;
      apiClient.menuIdToReturn = 'recovered-menu';

      expect(await menuService.currentMenuId(), 'recovered-menu');
      expect(apiClient.fetchMenuIdCalls, 2);
    });
  });

  group('createNewMenu', () {
    test('fetches, stores and caches a new menu id', () async {
      apiClient.menuIdToReturn = 'created-menu';

      expect(await menuService.createNewMenu(), 'created-menu');
      expect(storageService.savedMenuIds, <String>['created-menu']);
      expect(await menuService.currentMenuId(), 'created-menu');
      expect(apiClient.fetchMenuIdCalls, 1);
    });

    test('replaces a previously cached menu id', () async {
      storageService.storedMenuId = 'old-menu';
      await menuService.currentMenuId();

      apiClient.menuIdToReturn = 'created-menu';
      await menuService.createNewMenu();

      expect(await menuService.currentMenuId(), 'created-menu');
    });

    test('does not store the menu id when the api fails', () async {
      apiClient.fetchMenuIdError = ApiException(500, 'boom');

      await expectLater(menuService.createNewMenu(), throwsA(isA<ApiException>()));
      expect(storageService.savedMenuIds, isEmpty);
    });
  });

  group('joinMenu', () {
    test('validates, stores and caches the joined menu id', () async {
      await menuService.joinMenu('joined-menu');

      expect(apiClient.validatedMenuIds, <String>['joined-menu']);
      expect(storageService.savedMenuIds, <String>['joined-menu']);
      expect(await menuService.currentMenuId(), 'joined-menu');
      expect(apiClient.fetchMenuIdCalls, 0);
    });

    test('does not store the menu id when validation fails', () async {
      apiClient.validateMenuIdError = ApiException(404, 'boom');

      await expectLater(
        menuService.joinMenu('joined-menu'),
        throwsA(isA<ApiException>()),
      );
      expect(storageService.savedMenuIds, isEmpty);
    });
  });
}
