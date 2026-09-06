import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:shared_menu/dto/meal.dart';
import 'package:shared_menu/l10n/app_localizations.dart';
import 'package:shared_menu/widgets/day_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  testWidgets('DayCard renders lunch and dinner meals', (WidgetTester tester) async {
    final date = DateTime(2024, 1, 15);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DayCard(
            date: date,
            lunchMeal: Meal(day: '2024-1-15', mealType: MealType.lunch, meal: 'Pasta'),
            dinnerMeal: Meal(day: '2024-1-15', mealType: MealType.dinner, meal: 'Pizza'),
            onMealUpdated: () {},
          ),
        ),
      ),
    );

    expect(find.text('Lunch: Pasta'), findsOneWidget);
    expect(find.text('Dinner: Pizza'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
  });
}
