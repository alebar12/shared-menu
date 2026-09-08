import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/meal_service.dart';
import 'package:shared_menu/services/menu_service.dart';
import 'package:shared_menu/widgets/daily_scroll_view.dart';
import 'package:shared_menu/widgets/day_card.dart';
import 'package:shared_menu/widgets/share_menu_view.dart';

import '../fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  late FakeApiClient apiClient;
  late FakeStorageService storageService;

  setUp(() {
    apiClient = FakeApiClient(menuIdToReturn: 'menu-2');
    storageService = FakeStorageService(storedMenuId: 'menu-1');
  });

  Future<void> pumpDailyScrollView(WidgetTester tester) {
    final menuService =
        MenuService(apiClient: apiClient, storageService: storageService);
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MenuService>.value(value: menuService),
          Provider<MealService>.value(
            value: MealService(apiClient: apiClient, menuService: menuService),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DailyScrollView(),
        ),
      ),
    );
  }

  Meal mealForToday(MealType mealType, String meal) {
    final now = DateTime.now();
    return Meal(
      day: '${now.year}-${now.month}-${now.day}',
      mealType: mealType,
      meal: meal,
    );
  }

  testWidgets('shows a progress indicator while the meals load', (tester) async {
    await pumpDailyScrollView(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders a card per day with the meals of the current menu',
      (tester) async {
    apiClient.mealsToReturn = <Meal>[
      mealForToday(MealType.lunch, 'Pasta'),
      mealForToday(MealType.dinner, 'Pizza'),
    ];

    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    expect(apiClient.fetchMealsMenuIds, <String>['menu-1']);
    expect(find.byType(DayCard), findsWidgets);
    expect(find.text('Lunch: Pasta'), findsOneWidget);
    expect(find.text('Dinner: Pizza'), findsOneWidget);
  });

  testWidgets('shows an error and retries when loading fails', (tester) async {
    apiClient.fetchMealsError = ApiException(500, 'boom');

    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Failed to load meals'), findsOneWidget);

    apiClient.fetchMealsError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(DayCard), findsWidgets);
  });

  testWidgets('creates a new menu and reloads the meals', (tester) async {
    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(apiClient.fetchMenuIdCalls, 1);
    expect(storageService.savedMenuIds, <String>['menu-2']);
    expect(apiClient.fetchMealsMenuIds, <String>['menu-1', 'menu-2']);
  });

  testWidgets('shows an error when creating a new menu fails', (tester) async {
    apiClient.fetchMenuIdError = ApiException(500, 'boom');
    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to create new menu'), findsOneWidget);
    expect(apiClient.fetchMealsMenuIds, <String>['menu-1']);
  });

  testWidgets('cancelling the create confirmation does nothing', (tester) async {
    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new menu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(apiClient.fetchMenuIdCalls, 0);
    expect(apiClient.fetchMealsMenuIds, <String>['menu-1']);
  });

  testWidgets('opens the share view', (tester) async {
    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share my menu').last);
    await tester.pumpAndSettle();

    expect(find.byType(ShareMenuView), findsOneWidget);
  });
}
