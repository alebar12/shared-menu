import 'package:flutter_test/flutter_test.dart';
import 'package:shared_menu/clients/api_client.dart';
import 'package:shared_menu/dto/meal.dart';

void main() {
  group('Meal.fromJson', () {
    test('maps all fields', () {
      final meal = Meal.fromJson(<String, dynamic>{
        'day': '2024-01-15',
        'mealType': 'DINNER',
        'meal': 'Pizza',
      });

      expect(meal.day, '2024-01-15');
      expect(meal.mealType, MealType.dinner);
      expect(meal.meal, 'Pizza');
    });

    test('matches meal type case insensitively', () {
      final meal = Meal.fromJson(<String, dynamic>{
        'day': '2024-01-15',
        'mealType': 'Lunch',
        'meal': 'Pasta',
      });

      expect(meal.mealType, MealType.lunch);
    });

    test('falls back to lunch on unknown meal type', () {
      final meal = Meal.fromJson(<String, dynamic>{
        'day': '2024-01-15',
        'mealType': 'BRUNCH',
        'meal': 'Eggs',
      });

      expect(meal.mealType, MealType.lunch);
    });

    test('falls back to lunch when meal type is missing', () {
      final meal = Meal.fromJson(<String, dynamic>{'day': '2024-01-15'});

      expect(meal.mealType, MealType.lunch);
    });

    test('defaults day and meal to empty strings when missing', () {
      final meal = Meal.fromJson(<String, dynamic>{});

      expect(meal.day, '');
      expect(meal.meal, '');
    });
  });

  group('parseDay', () {
    test('parses a zero padded day', () {
      final meal = Meal(day: '2024-01-15', mealType: MealType.lunch, meal: 'Pasta');

      expect(meal.parseDay(), DateTime(2024, 1, 15));
    });

    test('parses a non padded day', () {
      final meal = Meal(day: '2024-1-5', mealType: MealType.lunch, meal: 'Pasta');

      expect(meal.parseDay(), DateTime(2024, 1, 5));
    });

    test('throws on an unparsable day', () {
      final meal = Meal(day: 'not-a-date', mealType: MealType.lunch, meal: 'Pasta');

      expect(meal.parseDay, throwsFormatException);
    });
  });

  group('parseMeals', () {
    test('parses a list of meals', () {
      final meals = parseMeals(
        '[{"day":"2024-01-15","mealType":"LUNCH","meal":"Pasta"},'
        '{"day":"2024-01-15","mealType":"DINNER","meal":"Pizza"}]',
      );

      expect(meals, hasLength(2));
      expect(meals.first.mealType, MealType.lunch);
      expect(meals.last.meal, 'Pizza');
    });

    test('parses an empty list', () {
      expect(parseMeals('[]'), isEmpty);
    });
  });

  group('ApiException', () {
    test('exposes status code and message', () {
      final exception = ApiException(404, 'Not found');

      expect(exception.statusCode, 404);
      expect(exception.message, 'Not found');
      expect(exception.toString(), 'ApiException(404): Not found');
    });
  });
}
