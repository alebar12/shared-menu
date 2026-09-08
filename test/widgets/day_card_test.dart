import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/services/meal_service.dart';
import 'package:shared_menu/services/menu_service.dart';
import 'package:shared_menu/widgets/day_card.dart';

import '../fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  late FakeApiClient apiClient;
  late MealService mealService;

  setUp(() {
    apiClient = FakeApiClient();
    mealService = MealService(
      apiClient: apiClient,
      menuService: MenuService(
        apiClient: apiClient,
        storageService: FakeStorageService(storedMenuId: 'menu-1'),
      ),
    );
  });

  Future<void> pumpDayCard(
    WidgetTester tester, {
    required DateTime date,
    Meal? lunchMeal,
    Meal? dinnerMeal,
    VoidCallback? onMealUpdated,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Provider<MealService>.value(
          value: mealService,
          child: Scaffold(
            body: DayCard(
              date: date,
              lunchMeal: lunchMeal,
              dinnerMeal: dinnerMeal,
              onMealUpdated: onMealUpdated ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  test('formats the date for the given locale', () {
    final dayCard = DayCard(
      date: DateTime(2024, 1, 15),
      lunchMeal: null,
      dinnerMeal: null,
      onMealUpdated: () {},
    );

    expect(dayCard.getFormattedDate('en'), 'Monday 15 January');
    expect(dayCard.getFormattedDate('it'), 'lunedì 15 gennaio');
  });

  testWidgets('renders lunch and dinner meals', (tester) async {
    await pumpDayCard(
      tester,
      date: DateTime(2024, 1, 15),
      lunchMeal:
          Meal(day: '2024-1-15', mealType: MealType.lunch, meal: 'Pasta'),
      dinnerMeal:
          Meal(day: '2024-1-15', mealType: MealType.dinner, meal: 'Pizza'),
    );

    expect(find.text('Monday 15 January'), findsOneWidget);
    expect(find.text('Lunch: Pasta'), findsOneWidget);
    expect(find.text('Dinner: Pizza'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
  });

  testWidgets('renders empty labels when there are no meals', (tester) async {
    await pumpDayCard(tester, date: DateTime(2024, 1, 15));

    expect(find.text('Lunch: '), findsOneWidget);
    expect(find.text('Dinner: '), findsOneWidget);
  });

  testWidgets('uses the highlight color on sundays', (tester) async {
    await pumpDayCard(tester, date: DateTime(2024, 1, 14));

    final theme = Theme.of(tester.element(find.byType(Card)));
    expect(tester.widget<Card>(find.byType(Card)).color,
        theme.colorScheme.inversePrimary);
  });

  testWidgets('uses the default color on other days', (tester) async {
    await pumpDayCard(tester, date: DateTime(2024, 1, 15));

    final theme = Theme.of(tester.element(find.byType(Card)));
    expect(tester.widget<Card>(find.byType(Card)).color,
        theme.colorScheme.primaryContainer);
  });

  testWidgets('opens the edit dialog with the current meal', (tester) async {
    await pumpDayCard(
      tester,
      date: DateTime(2024, 1, 15),
      lunchMeal:
          Meal(day: '2024-1-15', mealType: MealType.lunch, meal: 'Pasta'),
    );

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Pasta'), findsOneWidget);
  });

  testWidgets('saves the edited meal and notifies the parent', (tester) async {
    var notified = 0;
    await pumpDayCard(
      tester,
      date: DateTime(2024, 1, 15),
      dinnerMeal:
          Meal(day: '2024-1-15', mealType: MealType.dinner, meal: 'Pizza'),
      onMealUpdated: () => notified++,
    );

    await tester.tap(find.byIcon(Icons.edit).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lasagna');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    final posted = apiClient.postedMeals.single;
    expect(posted.menuId, 'menu-1');
    expect(posted.meal, 'Lasagna');
    expect(posted.day, DateTime(2024, 1, 15));
    expect(posted.mealType, MealType.dinner);
    expect(notified, 1);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows an error and keeps the dialog open when saving fails',
      (tester) async {
    apiClient.postMealError = ApiException(500, 'boom');
    var notified = 0;
    await pumpDayCard(
      tester,
      date: DateTime(2024, 1, 15),
      onMealUpdated: () => notified++,
    );

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to save meal'), findsOneWidget);
    expect(notified, 0);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('cancelling the dialog does not save anything', (tester) async {
    var notified = 0;
    await pumpDayCard(
      tester,
      date: DateTime(2024, 1, 15),
      onMealUpdated: () => notified++,
    );

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(apiClient.postedMeals, isEmpty);
    expect(notified, 0);
    expect(find.byType(TextField), findsNothing);
  });
}
