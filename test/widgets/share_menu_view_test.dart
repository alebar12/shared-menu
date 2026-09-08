import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/menu_service.dart';
import 'package:shared_menu/widgets/share_menu_view.dart';

import '../fakes.dart';

void main() {
  late FakeApiClient apiClient;
  late FakeStorageService storageService;

  setUp(() {
    apiClient = FakeApiClient();
    storageService = FakeStorageService();
  });

  Future<void> pumpShareMenuView(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Provider<MenuService>.value(
          value: MenuService(apiClient: apiClient, storageService: storageService),
          child: const ShareMenuView(),
        ),
      ),
    );
  }

  testWidgets('shows a progress indicator while the menu id loads',
      (tester) async {
    await pumpShareMenuView(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders the qr code of the current menu id', (tester) async {
    storageService.storedMenuId = 'menu-1';

    await pumpShareMenuView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Share my menu'), findsOneWidget);
    expect(find.text('Scan this QR code to join the menu'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(apiClient.fetchMenuIdCalls, 0);
  });

  testWidgets('shows an error and retries when loading fails', (tester) async {
    apiClient.fetchMenuIdError = ApiException(500, 'boom');

    await pumpShareMenuView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Failed to load menu id'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    apiClient.fetchMenuIdError = null;
    apiClient.menuIdToReturn = 'menu-2';
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Failed to load menu id'), findsNothing);
    expect(storageService.savedMenuIds, <String>['menu-2']);
  });
}
