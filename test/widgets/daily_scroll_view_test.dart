import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/crypto_service.dart';
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
    final cryptoService = CryptoService();
    final menuService = MenuService(
      apiClient: apiClient,
      storageService: storageService,
      cryptoService: cryptoService,
    );
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MenuService>.value(value: menuService),
          Provider<MealService>.value(
            value: MealService(
              apiClient: apiClient,
              menuService: menuService,
              cryptoService: cryptoService,
            ),
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

  Future<Meal> mealForDay(int dayOffset, MealType mealType, String meal,
      {String secret = fakeMenuSecret}) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day + dayOffset);
    return encryptedMeal(
      day: '${day.year}-${day.month}-${day.day}',
      mealType: mealType,
      meal: meal,
      secret: secret,
    );
  }

  Future<Meal> mealForToday(MealType mealType, String meal,
          {String secret = fakeMenuSecret}) =>
      mealForDay(0, mealType, meal, secret: secret);

  testWidgets('shows a progress indicator while the meals load',
      (tester) async {
    await pumpDailyScrollView(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders a card per day with the meals of the current menu',
      (tester) async {
    apiClient.mealsToReturn = <Meal>[
      await mealForToday(MealType.lunch, 'Pasta'),
      await mealForToday(MealType.dinner, 'Pizza'),
    ];

    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    expect(apiClient.fetchMealsMenuIds, <String>['menu-1']);
    expect(find.byType(DayCard), findsWidgets);
    expect(find.text('Lunch: Pasta'), findsOneWidget);
    expect(find.text('Dinner: Pizza'), findsOneWidget);
  });

  testWidgets('assigns every meal to the card of its own day', (tester) async {
    apiClient.mealsToReturn = <Meal>[
      await mealForToday(MealType.lunch, 'Pasta'),
      await mealForDay(1, MealType.dinner, 'Soup'),
    ];

    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final cards = tester.widgetList<DayCard>(find.byType(DayCard));
    final todayCard = cards.firstWhere((card) => card.date == startOfToday);
    final tomorrowCard = cards.firstWhere(
      (card) => card.date == startOfToday.add(const Duration(days: 1)),
    );

    expect(todayCard.lunchMeal?.meal, 'Pasta');
    expect(todayCard.dinnerMeal, isNull);
    expect(tomorrowCard.lunchMeal, isNull);
    expect(tomorrowCard.dinnerMeal?.meal, 'Soup');
  });

  testWidgets('pull to refresh keeps the indicator until the reload completes',
      (tester) async {
    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    final gate = Completer<void>();
    apiClient.fetchMealsGate = gate;

    await tester.fling(
        find.byType(CustomScrollView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(apiClient.fetchMealsMenuIds, <String>['menu-1', 'menu-1']);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('resuming on the same day does not reload the meals',
      (tester) async {
    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(apiClient.fetchMealsMenuIds, <String>['menu-1']);
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

  testWidgets('replaces the menu when none of its meals can be decrypted',
      (tester) async {
    apiClient.mealsByMenuId['menu-1'] = <Meal>[
      await mealForToday(MealType.lunch, 'Pasta', secret: 'another-secret'),
    ];
    apiClient.mealsByMenuId['menu-2'] = const <Meal>[];

    await pumpDailyScrollView(tester);
    await tester.pumpAndSettle();

    expect(find.text('This menu is corrupted, a new menu will be created'),
        findsOneWidget);
    expect(storageService.savedMenuIds, <String>['menu-2']);
    expect(apiClient.fetchMealsMenuIds, <String>['menu-1', 'menu-2']);
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

  testWidgets('cancelling the create confirmation does nothing',
      (tester) async {
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
