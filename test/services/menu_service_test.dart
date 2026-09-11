import 'package:flutter_test/flutter_test.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/services/crypto_service.dart';
import 'package:shared_menu/services/menu_service.dart';

import '../fakes.dart';

void main() {
  late FakeApiClient apiClient;
  late FakeStorageService storageService;
  late MenuService menuService;

  setUp(() {
    apiClient = FakeApiClient();
    storageService = FakeStorageService();
    menuService = MenuService(
      apiClient: apiClient,
      storageService: storageService,
      cryptoService: CryptoService(),
    );
  });

  group('currentCredentials', () {
    test('returns the stored menu id and secret without calling the api',
        () async {
      storageService.storedMenuId = 'stored-menu';
      storageService.storedMenuSecret = 'stored-secret';

      final credentials = await menuService.currentCredentials();

      expect(credentials.menuId, 'stored-menu');
      expect(credentials.secret, 'stored-secret');
      expect(apiClient.fetchMenuIdCalls, 0);
      expect(storageService.savedMenuIds, isEmpty);
      expect(storageService.savedMenuSecrets, isEmpty);
    });

    test('creates a menu id and a random secret when none is stored', () async {
      apiClient.menuIdToReturn = 'new-menu';

      final credentials = await menuService.currentCredentials();

      expect(credentials.menuId, 'new-menu');
      expect(credentials.secret, matches(r'^[A-Za-z0-9]{32}$'));
      expect(apiClient.fetchMenuIdCalls, 1);
      expect(storageService.savedMenuIds, <String>['new-menu']);
      expect(storageService.savedMenuSecrets, <String>[credentials.secret]);
    });

    test('creates a new menu when the stored menu id has no secret', () async {
      storageService.storedMenuId = 'stored-menu';
      storageService.storedMenuSecret = null;
      apiClient.menuIdToReturn = 'new-menu';

      final credentials = await menuService.currentCredentials();

      expect(credentials.menuId, 'new-menu');
      expect(storageService.savedMenuSecrets.single, credentials.secret);
    });

    test('generates a different secret for every new menu', () async {
      final first = await menuService.createNewMenu();
      final second = await menuService.createNewMenu();

      expect(first.secret, isNot(second.secret));
    });
  });

  group('currentMenuId', () {
    test('returns the stored menu id without calling the api', () async {
      storageService.storedMenuId = 'stored-menu';
      storageService.storedMenuSecret = 'stored-secret';

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
      await expectLater(
          menuService.currentMenuId(), throwsA(isA<ApiException>()));

      apiClient.fetchMenuIdError = null;
      apiClient.menuIdToReturn = 'recovered-menu';

      expect(await menuService.currentMenuId(), 'recovered-menu');
      expect(apiClient.fetchMenuIdCalls, 2);
    });
  });

  group('createNewMenu', () {
    test('fetches, stores and caches a new menu id and secret', () async {
      apiClient.menuIdToReturn = 'created-menu';

      final credentials = await menuService.createNewMenu();

      expect(credentials.menuId, 'created-menu');
      expect(storageService.savedMenuIds, <String>['created-menu']);
      expect(storageService.savedMenuSecrets, <String>[credentials.secret]);
      expect(await menuService.currentMenuId(), 'created-menu');
      expect(apiClient.fetchMenuIdCalls, 1);
    });

    test('replaces a previously cached menu id', () async {
      storageService.storedMenuId = 'old-menu';
      storageService.storedMenuSecret = 'old-secret';
      await menuService.currentMenuId();

      apiClient.menuIdToReturn = 'created-menu';
      await menuService.createNewMenu();

      expect(await menuService.currentMenuId(), 'created-menu');
      expect((await menuService.currentCredentials()).secret,
          isNot('old-secret'));
    });

    test('does not store the menu id when the api fails', () async {
      apiClient.fetchMenuIdError = ApiException(500, 'boom');

      await expectLater(
          menuService.createNewMenu(), throwsA(isA<ApiException>()));
      expect(storageService.savedMenuIds, isEmpty);
      expect(storageService.savedMenuSecrets, isEmpty);
    });
  });

  group('joinMenu', () {
    test('validates, stores and caches the scanned menu id and secret',
        () async {
      await menuService.joinMenu(
          fakeQrPayload(menuId: 'joined-menu', secret: 'joined-secret'));

      expect(apiClient.validatedMenuIds, <String>['joined-menu']);
      expect(storageService.savedMenuIds, <String>['joined-menu']);
      expect(storageService.savedMenuSecrets, <String>['joined-secret']);
      expect((await menuService.currentCredentials()).secret, 'joined-secret');
      expect(apiClient.fetchMenuIdCalls, 0);
    });

    test('does not store anything when validation fails', () async {
      apiClient.validateMenuIdError = ApiException(404, 'boom');

      await expectLater(
        menuService.joinMenu(fakeQrPayload(menuId: 'joined-menu')),
        throwsA(isA<ApiException>()),
      );
      expect(storageService.savedMenuIds, isEmpty);
      expect(storageService.savedMenuSecrets, isEmpty);
    });

    test('rejects a payload that is not a menu', () async {
      await expectLater(
        menuService.joinMenu('joined-menu'),
        throwsA(isA<FormatException>()),
      );
      expect(apiClient.validatedMenuIds, isEmpty);
      expect(storageService.savedMenuIds, isEmpty);
    });

    test('rejects a payload without a secret', () async {
      await expectLater(
        menuService.joinMenu('{"menuId":"joined-menu"}'),
        throwsA(isA<FormatException>()),
      );
      expect(apiClient.validatedMenuIds, isEmpty);
    });
  });
}
